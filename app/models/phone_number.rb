class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls
  
  def self.get_salesforce_numbers
    campaigns = Salesforce::Clientcampaign.all
    
    campaigns.each do |campaign|
      local_campaign = Campaign.find_by_name(campaign.name)
      if local_campaign.present?
        if campaign.primary_tracking_number__c != nil
          number = campaign.primary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          new_phone = PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.primary_marchex_id__c,
                                                                        :inboundno => number,
                                                                        :name => campaign.name,
                                                                        :campaign_id => local_campaign.id,
                                                                        :descript => campaign.name)
        end
      
        if campaign.secondary_tracking_number__c != nil
          number = campaign.secondary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          new_phone = PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.secondary_marchex_id__c,
                                                                        :inboundno => campaign.secondary_tracking_number__c,
                                                                        :name => campaign.name,
                                                                        :campaign_id => local_campaign.id,
                                                                        :descript => campaign.name)
        end
      
        if campaign.third_tracking_number__c != nil
          number = campaign.third_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          new_phone = PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.third_marchex_id__c,
                                                                        :inboundno => campaign.third_tracking_number__c,
                                                                        :name => campaign.name,
                                                                        :campaign_id => local_campaign.id,
                                                                        :descript => campaign.name)
        end
      end
    end
  end
end
