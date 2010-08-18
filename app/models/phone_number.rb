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
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => sf_campaign.primary_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => sf_campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => sf_campaign.name)
        end

        if sf_campaign.secondary_tracking_number__c.present?
          number = sf_campaign.secondary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => sf_campaign.secondary_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => sf_campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => sf_campaign.name)
        end

        if sf_campaign.third_tracking_number__c.present?
          number = sf_campaign.third_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => sf_campaign.third_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => sf_campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => sf_campaign.name)
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

end
