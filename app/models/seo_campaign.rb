class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords
  has_many :inbound_links
  has_many :website_analyses, :class_name => "WebsiteAnalysis"


  # CLASS BEHAVIOR

  def self.update_inbound_links
    seo_campaigns = SeoCampaign.all
    seo_campaigns.each do |seo_campaign|
      websites = seo_campaign.websites
      if websites.present?
        websites.each do |website|
          freshness = seo_campaign.inbound_links.find(:all, :conditions => ['created_at > ?', 1.day.ago])
          begin
            if freshness.empty? && website.nickname.present?
              url = 'http://perl.pearanalytics.com/v2/domain/get/linklist?url=http://' + website.nickname.gsub('http://', '')
              response = HTTParty.get(url)
              links = JSON.parse(response)['result']
              if links.present?
                links.each do |link|
                  existing_link = InboundLink.find_by_link_url_and_seo_campaign_id(link, seo_campaign.id)
                  if existing_link.present?
                    existing_link.last_date_found = Date.today
                    existing_link.save
                  else
                    InboundLink.create(:link_url => link, :seo_campaign_id => seo_campaign.id, :last_date_found => Date.today, :is_active => true)
                  end
                end
              end
            end
          rescue
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
        link.save!
      end
    end
  end

  def self.update_website_analyses
    seo_campaigns = SeoCampaign.all
    seo_campaigns.each do |seo_campaign|
      websites = seo_campaign.websites
      if websites.present?
        websites.each do |website|
          freshness = seo_campaign.website_analyses.find(:all, :conditions => ['created_at > ?', 1.day.ago])
          if freshness.empty? && website.nickname.present?
            pearscore = seo_campaign.getpearscore(website.nickname)
            google_pagerank = seo_campaign.getgooglepagerank(website.nickname)
            alexa_rank = seo_campaign.getalexarank(website.nickname)
            sitewide_inbound_link_count = seo_campaign.get_sitewide_inbound_link_count(website.nickname)
            page_specific_inbound_link_count = seo_campaign.get_page_specific_inbound_link_count(website.nickname)
            WebsiteAnalysis.create(:seo_campaign_id => seo_campaign.id, :pear_score => pearscore, :google_pagerank => google_pagerank, :alexa_rank => alexa_rank, :sitewide_inbound_link_count => sitewide_inbound_link_count, :page_specific_inbound_link_count => page_specific_inbound_link_count)
          end
        end
      end
    end
  end


  # INSTANCE BEHAVIOR

  def getpearscore(nickname)
    begin
      url = build_pear_url("linkanalysis/getpearscore", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["pear_score"]
    rescue
      puts "Error in Account.getpearscore"
      return nil
    end
  end

  def getgooglepagerank(nickname)
    begin
      url = build_pear_url("linkanalysis/getgooglepagerank", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["google_pagerank"]
    rescue
      puts "Error in Account.getgooglepagerank"
      return nil
    end
  end

  def get_new_google_page_rank(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/rank/google?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.getgooglepagerank"
      return nil
    end
  end

  def getalexarank(nickname)
    begin
      url = build_pear_url("linkanalysis/getalexarank", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["alexa_rank"]
    rescue
      puts "Error in Account.getalexarank"
      return nil
    end
  end

  def get_new_alexa_rank(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/rank/alexa?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_alexa_rank"
      return nil
    end
  end

  def get_page_specific_inbound_link_count(nickname)
    begin
      url = build_pear_url("linkanalysis/getinboundlinkcount", {"url" => nickname, "format" => "json", "page_specific" => "1"})
      response = HTTParty.get(url)
      response["inbound_link_count"]
    rescue
      puts "Error in Account.get_page_specific_inbound_link_count"
      return nil
    end
  end

  def get_sitewide_inbound_link_count(nickname)
    begin
      url = build_pear_url("linkanalysis/getinboundlinkcount", {"url" => nickname, "format" => "json", "page_specific" => "0"})
      response = HTTParty.get(url)
      response["inbound_link_count"]
    rescue
      puts "Error in Account.get_sitewide_inbound_link_count"
      return nil
    end
  end

  def get_new_sitewide_inbound_link_count(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/get/links?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_sitewide_inbound_link_count"
      return nil
    end
  end

  def get_new_html_validation_errors(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/valid/html?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']['errors']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_load_time(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/loadtime?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']['time']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_site_map_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/sitemap?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_robots_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/robots?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_404_response_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/404-response?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
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

  def spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (spend = self.budget).present? ? spend : 0.0
  end

end
