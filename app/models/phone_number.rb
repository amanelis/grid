class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls

  def self.get_salesforce_numbers
    sf_campaigns = Salesforce::Clientcampaign.all

    sf_campaigns.each do |campaign|
      local_campaign = Campaign.find_by_name(campaign.name)
      if local_campaign.present?
        if campaign.primary_tracking_number__c.present?
          number = campaign.primary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.primary_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => campaign.name)
        end

        if campaign.secondary_tracking_number__c.present?
          number = campaign.secondary_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.secondary_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => campaign.name)
        end

        if campaign.third_tracking_number__c.present?
          number = campaign.third_tracking_number__c.gsub('(', '').gsub(')', '').gsub('-', '').gsub(' ', '')
          PhoneNumber.find_or_create_by_cmpid_and_inboundno(:cmpid => campaign.third_marchex_id__c,
                                                            :inboundno => number,
                                                            :name => campaign.name,
                                                            :campaign_id => local_campaign.id,
                                                            :descript => campaign.name)
        end
      end
    end
  end
end
