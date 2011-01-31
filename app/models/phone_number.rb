require 'xmlrpc/client'
require 'xmlrpc/datetime'

class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls, :dependent => :destroy

  # Twilio REST API version
  API_VERSION = '2010-04-01'

  # Twilio AccountSid and AuthToken
  ACCOUNT_SID = 'AC7fedbe5d54f77671320418d20f843330'
  ACCOUNT_TOKEN = 'a7a72b0eb3c8a41064c4fc741674a903'
  

  # CLASS BEHAVIOR

  def self.get_marchex_numbers
    job_status = JobStatus.create(:name => "PhoneNumber.get_marchex_numbers")
    orphan_campaign = Campaign.orphanage
    begin
      server = XMLRPC::Client.new("api.voicestar.com", "/api/xmlrpc/1", 80)
      # or http://api.voicestar.com/
      server.user = 'reporting@cityvoice.com'
      server.password = 'C1tyv01c3'
      results = server.call("acct.list")
      results.each do |result|
        group_results = server.call("group.list", result["acct"])
        group_results.each do |group_result|
          grpid = group_result["grpid"]
          ad_results = server.call("ad.list", grpid)
          ad_results.each do |ad_result|
            phone_number = PhoneNumber.find_by_cmpid_and_inboundno(ad_result["cmpid"], ad_result["inboundno"])
            if phone_number.blank?
              phone_number = orphan_campaign.phone_numbers.build
              phone_number.inboundno = ad_result["inboundno"]
              phone_number.cmpid = ad_result["cmpid"]
            end
            phone_number.descript = ad_result["descript"]
            phone_number.name = ad_result["name"]
            phone_number.save!
          end
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

  def self.get_salesforce_numbers  
    job_status = JobStatus.create(:name => "PhoneNumber.get_salesforce_numbers *SHOULDN'T BE RUN*")
    begin
      sf_campaigns = Salesforce::Clientcampaign.all
      sf_campaigns.each do |sf_campaign|
        local_campaign = Campaign.find_by_name(sf_campaign.name)
        if local_campaign.present?
          if sf_campaign.primary_tracking_number__c.present?
            number = sf_campaign.primary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
            existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.primary_marchex_id__c, number)
            if existing_number.present?
              existing_number.campaign_id = local_campaign.id
              existing_number.name = sf_campaign.name
              existing_number.descript = sf_campaign.name
              existing_number.save!
            end
          end
          
          if sf_campaign.secondary_tracking_number__c.present?
            number = sf_campaign.secondary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
            existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.secondary_marchex_id__c, number)
            if existing_number.present?
              existing_number.campaign_id = local_campaign.id
              existing_number.name = sf_campaign.name
              existing_number.descript = sf_campaign.name
              existing_number.save!
            end
          end

          if sf_campaign.third_tracking_number__c.present?
            number = sf_campaign.third_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
            existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.third_marchex_id__c, number)
            if existing_number.present?
              existing_number.campaign_id = local_campaign.id
              existing_number.name = sf_campaign.name
              existing_number.descript = sf_campaign.name
              existing_number.save!
            end
          end
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

  def self.orphaned_phone_numbers
    Campaign.orphanage.phone_numbers
  end
  
  def self.selectable_orphaned_phone_numbers
    self.orphaned_phone_numbers.collect { |orphan| ["#{orphan.name} - #{orphan.inboundno}", orphan.id] }.sort { |x, y| x.first.downcase <=> y.first.downcase }
  end
  
  #Returns an Array of Hashes for Available Phone Numbers within an area_code.
  def self.available_numbers(area_code = "210", country = "US")
    account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
    resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/AvailablePhoneNumbers/#{country}/Local.json?AreaCode=#{area_code}", 'GET')
    resp.error! unless resp.kind_of? Net::HTTPSuccess
    if resp.code == '200'
      results = JSON.parse(resp.body)['available_phone_numbers']
      return results.sort {|a,b| a["phone_number"].to_i <=> b["phone_number"].to_i}
    end
  end
  

  # INSTANCE BEHAVIOR

  def update_twilio_number(name, forward_to, id_callers = true, record_calls = true, transcribe_calls = false, text_calls = false, call_url = "http://grid.cityvoice.com/phone_numbers/connect/", fallback_url = "http://grid.cityvoice.com/phone_numbers/connect/", status_url = "http://grid.cityvoice.com/phone_numbers/collect/", sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/", fallback_sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/")
    job_status = JobStatus.create(:name => "PhoneNumber.update_twilio_number")
    begin
      #CREATE THE NUMBER IN TWILIO (BASIC INFORMATION)
      account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
      #UPDATE THE TWILIO URLS
      d = { 'FriendlyName' => name,
            'VoiceUrl' => "#{call_url}#{self.id}",
            'VoiceMethod' => 'POST',
            'VoiceFallbackUrl' => "#{fallback_url}#{self.id}",
            'VoiceFallbackMethod' => 'POST',
            'StatusCallback' => "#{status_url}#{self.id}",
            'StatusCallbackMethod' => 'POST',
            'SmsUrl' => "#{sms_url}#{self.id}",
            'SmsMethod' => 'POST',
            'SmsFallbackUrl' => "#{fallback_sms_url}#{self.id}",
            'SmsFallbackMethod' => 'POST',
            'VoiceCallerIdLookup' => id_callers
          }
      update_resp = account.request("/#{self.twilio_version}/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers/#{self.twilio_id}.json", 'POST', d)
      raise unless update_resp.kind_of? Net::HTTPSuccess
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
    true
  end
  
  def orphan!
    self.campaign_id = Campaign.orphanage.id
    self.save!
  end

  def number_of_answered_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.answered.between(start_date, end_date).count
  end

  def number_of_canceled_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.canceled.between(start_date, end_date).count
  end

  def number_of_voicemail_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.voicemail.between(start_date, end_date).count
  end

  def number_of_other_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.other.between(start_date, end_date).count
  end

  def number_of_all_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.between(start_date, end_date).count
  end

  def number_of_answered_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.answered, :answered)
  end

  def number_of_canceled_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.canceled, :canceled)
  end

  def number_of_voicemail_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.voicemail, :voicemail)
  end

  def number_of_other_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.other, :other)
  end

  def number_of_specific_calls_labeled_by_date(specific_calls, label)
    specific_calls.count(:group => "date(call_start)", :order =>"call_start ASC").inject({}) { |data, (key, value)| data[key.to_date] = {label => value}; data }
  end

  def call_timeline_data
    Utilities.merge_timeline_data(self.number_of_answered_calls_by_date, self.number_of_canceled_calls_by_date, self.number_of_voicemail_calls_by_date, self.number_of_other_calls_by_date)
  end

end
