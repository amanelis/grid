class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls


  # CLASS BEHAVIOR

  def self.get_salesforce_numbers
    sf_campaigns = Salesforce::Clientcampaign.all

    sf_campaigns.each do |sf_campaign|
      local_campaign = Campaign.find_by_name(sf_campaign.name)
      if local_campaign.present?
        if sf_campaign.primary_tracking_number__c.present?
          number = sf_campaign.primary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.primary_marchex_id__c, number)
          if existing_number.blank?
             existing_number = PhoneNumber.new
             existing_number.cmpid = sf_campaign.primary_marchex_id__c
             existing_number.inboundno = number
          end
          existing_number.name = sf_campaign.name,
          existing_number.campaign_id = local_campaign.id
          existing_number.descript = sf_campaign.name
          existing_number.save
        end
        if sf_campaign.secondary_tracking_number__c.present?
          number = sf_campaign.secondary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.secondary_marchex_id__c, number)
          if existing_number.blank?
             existing_number = PhoneNumber.new
             existing_number.cmpid = sf_campaign.secondary_marchex_id__c
             existing_number.inboundno = number
          end
          existing_number.name = sf_campaign.name,
          existing_number.campaign_id = local_campaign.id
          existing_number.descript = sf_campaign.name
          existing_number.save
        end

        if sf_campaign.third_tracking_number__c.present?
          number = sf_campaign.third_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          existing_number = PhoneNumber.find_by_cmpid_and_inboundno(sf_campaign.third_marchex_id__c, number)
          if existing_number.blank?
             existing_number = PhoneNumber.new
             existing_number.cmpid = sf_campaign.third_marchex_id__c
             existing_number.inboundno = number
          end
          existing_number.name = sf_campaign.name,
          existing_number.campaign_id = local_campaign.id
          existing_number.descript = sf_campaign.name
          existing_number.save
        end
      end
    end
  end


  # INSTANCE BEHAVIOR

  def number_of_answered_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.answered.between(start_date, end_date).count
  end

  def number_of_canceled_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.canceled.between(start_date, end_date).count
  end

  def number_of_voicemail_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.voicemail.between(start_date, end_date).count
  end

  def number_of_other_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.other.between(start_date, end_date).count
  end

  def number_of_all_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
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
    specific_calls.count(:group => "date(call_start)", :order =>"call_start ASC").inject({}) {|data, (key, value)| data[key.to_date] = {label => value} ; data}
  end

  def call_timeline_data
    Utilities.merge_timeline_data(self.number_of_answered_calls_by_date, self.number_of_canceled_calls_by_date, self.number_of_voicemail_calls_by_date, self.number_of_other_calls_by_date)
  end

end
