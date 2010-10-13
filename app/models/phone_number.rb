require 'xmlrpc/client'
require 'xmlrpc/datetime'


class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls, :dependent => :destroy


  # CLASS BEHAVIOR

  def self.get_salesforce_numbers
    job_status = JobStatus.create(:name => "PhoneNumber.get_salesforce_numbers")
    orphan_campaign = Campaign.orphanage
    
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


  # INSTANCE BEHAVIOR

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
