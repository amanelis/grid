class Keyword < ActiveRecord::Base
  belongs_to :seo_campaign
  has_many :analyses, :class_name => "KeywordAnalysis"
  
  def self.update_keywords_from_salesforce
    campaigns = Salesforce::Clientcampaign.find(:all, :conditions => ['campaign_type__c = ?', 'SEO'])
    
    campaigns.each do |campaign|
      local_campaign = Campaign.find_by_name(campaign.name)
      if campaign.keywords__c.present? && local_campaign.present?
        keywords = campaign.keywords__c.split(',')
        keywords.each do |keyword|
          puts 'Started: ' + keyword
          new_keyword = Keyword.find_or_create_by_seo_campaign_id_and_descriptor(:seo_campaign_id => local_campaign.id,
                                                                                 :descriptor => keyword,
                                                                                 :google_first_page => false,
                                                                                 :yahoo_first_page => false,
                                                                                 :bing_first_page => false)
          new_keyword.save
          puts 'Completed: ' + keyword
        end
      end
    end
  end
  
  
end
