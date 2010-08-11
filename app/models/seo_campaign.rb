class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords
  has_many :inbound_links
  has_many :website_analyses, :class_name => "WebsiteAnalysis"
  
   def self.update_inbound_links
     seo_campaigns = SeoCampaign.all
     seo_campaigns.each do |seo_campaign|
       if seo_campaign.websites.present?
         freshness = seo_campaign.inbound_links.find(:all, :conditions => ['created_at > ?', 1.day.ago])
         if freshness.size == 0 && seo_campaign.websites.first.nickname.present?
           url = seo_campaign.build_pear_url("linkanalysis/getinboundlinks", { "url" => seo_campaign.websites.first.nickname, "format" => "json", "page_specific" => "0" })
           response = HTTParty.get(url)
           links = response["inbound_links"]
           if links != nil
             links.each do |link|
               new_link = InboundLink.find_or_create_by_link_url_and_seo_campaign_id(:link_url => link, :seo_campaign_id => seo_campaign.id, :last_date_found => Date.today, :is_active => true)
               new_link.save
             end
           end
         end
       end
     end
   end
   
   def self.clean_up_inbound_links
     links = InboundLink.all
     
     links.each do |link|
       if link.last_date_found < (Date.today - 60.days)
         link.is_active = false
         link.save
       end
     end
   end
   
   def build_pear_url(uri, parameters, api_key = "819f9b322610b816c898899ddad715a2e76fc3c5", api_secret = "2c312c9626b79d2fa47321753a18a2672e4d58aa")
     parameters["signature"] = self.calculate_pear_signature(uri, parameters, api_secret)
     parameters["api_key"] = api_key
     pieces = []
     parameters.each { |key, value| pieces << CGI.escape(key) + '=' + CGI.escape(value) }
     "http://juice.pearanalytics.com/api.php/" + uri + '?' + pieces.join('&')
   end

   def calculate_pear_signature(uri, parameters, api_secret)
     parameters = parameters.sort()
     signature = uri.to_s() + ':' + api_secret.to_s() + '%'
     parameters.each { |key, value| signature += key.to_s() + '=' + value.to_s() + ';' }
     Digest::SHA1.hexdigest(signature)
   end
  
end
