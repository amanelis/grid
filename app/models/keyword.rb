require 'digest/sha1'
require 'cgi'

class Keyword < ActiveRecord::Base
  belongs_to :seo_campaign
  has_many :analyses, :class_name => "KeywordAnalysis"

  def self.update_keywords_from_salesforce
    sf_campaigns = Salesforce::Clientcampaign.find_all_by_campaign_type__c('SEO')
    sf_campaigns.each do |sf_campaign|
      local_seo_campaign = Campaign.find_by_name(sf_campaign.name).try(:campaign_style)
      if sf_campaign.keywords__c.present? && local_seo_campaign.present?
        keywords = sf_campaign.keywords__c.split(',')
        keywords.each do |keyword|
          puts 'Started: ' + keyword
          Keyword.find_or_create_by_seo_campaign_id_and_descriptor(:seo_campaign_id => local_seo_campaign.id,
                                                                   :descriptor => keyword,
                                                                   :google_first_page => false,
                                                                   :yahoo_first_page => false,
                                                                   :bing_first_page => false)
          puts 'Completed: ' + keyword
        end
      end
    end
  end

  def self.update_keyword_rankings
    Keyword.all.each { |keyword| keyword.fetch_keyword_analysis }
  end

  def fetch_keyword_analysis
    freshness = KeywordAnalysis.find_all_by_keyword_id_and_created_at(self, 1.day.ago)
    if freshness.empty?
      google = 99999
      bing = 99999
      yahoo = 99999
      relevancy = 0

      begin
        search_positions = get_search_positions
      rescue
      end
      begin
        google = search_positions["google"]
      rescue
      end
      begin
        bing = search_positions["bing"]
      rescue
      end
      begin
        yahoo = search_positions["yahoo"]
      rescue
      end
      begin
        relevancy = get_relevancy
      rescue
      end
      begin
        cpc = get_cpc
      rescue
      end

      self.analyses.create(:google => google, :bing => bing, :yahoo => yahoo, :cpc => cpc, :relevancy => relevancy)

    end
  end


  def get_search_positions
    # HACK: The rails belongs_to method seems to have a bug. self.url.url should give me the URL string, but it doesn't
    #Changed to Use Account instead of URL@url_obj = URL.find url_id
    begin
      url = self.build_pear_url("keyword/getsearchposition", {"url" => self.seo_campaign.websites.first.nickname, "query" => self.descriptor, "format" => "json"})
      HTTParty.get(url)
    rescue
    end
  end

  def get_relevancy
    # HACK: The rails belongs_to method seems to have a bug. self.url.url should give me the URL string, but it doesn't
    begin
      url = self.build_pear_url("keyword/getrelevancy", {"url" => self.seo_campaign.websites.first.nickname, "keyword" => self.descriptor, "format" => "json"})
      response = HTTParty.get(url)
      response["relevancy"]
    rescue
    end
  end

  def get_cpc
    # HACK: The rails belongs_to method seems to have a bug. self.url.url should give me the URL string, but it doesn't
    begin
      url = self.build_pear_url("keyword/getcpc", {"keyword" => self.descriptor, "format" => "json"})
      response = HTTParty.get(url)
      response["cpc"]
    rescue
    end
  end

  def build_pear_url(uri, parameters, api_key = "819f9b322610b816c898899ddad715a2e76fc3c5", api_secret = "2c312c9626b79d2fa47321753a18a2672e4d58aa")
    parameters["signature"] = calculate_pear_signature(uri, parameters, api_secret)
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
