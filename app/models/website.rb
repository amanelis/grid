class Website < ActiveRecord::Base
  has_and_belongs_to_many :campaigns
  has_many :website_visits


  def self.add_websites()
    #http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0
    geturl = HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0&output=json")
    response = geturl["response"]
    urls = response["site"]
    urls.each do |url|
      Website.find_or_create_by_site_id(:site_id => url["site_id"],
                                        :domain => url["hostname"].downcase,
                                        :nickname => url["nickname"].downcase,
                                        :sitekey => url["sitekey"],
                                        :database_server => url["server"],
                                        :admin_sitekey => url["sitekey_admin"],
                                        :is_active => true)
    end

    sf_campaigns = Salesforce::Clientcampaign.all

    sf_campaigns.each do |sf_campaign|
      website = Website.find_by_nickname(sf_campaign.primary_website__c)
      if website.present?
        local_campaign = Campaign.find_by_name(sf_campaign.name)
        if local_campaign.present?
          website.campaigns << local_campaign
          website.save
        end
      end
    end
  end

end

