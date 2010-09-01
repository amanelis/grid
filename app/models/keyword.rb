require 'digest/sha1'
require 'cgi'

class Keyword < ActiveRecord::Base
  belongs_to :seo_campaign
  has_many :keyword_rankings


  # CLASS BEHAVIOR

  def self.update_keywords_from_salesforce
    job_status = JobStatus.create(:name => "Keyword.update_keywords_from_salesforce")
    begin
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
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

  def self.update_keyword_rankings
    job_status = JobStatus.create(:name => "Keyword.update_keyword_rankings")
    begin
      Keyword.all.each { |keyword| keyword.fetch_keyword_rankings }
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end


  # INSTANCE BEHAVIOR

  def fetch_keyword_rankings
    freshness = KeywordRanking.find(:all, :conditions => ['created_at > ? && keyword_id = ?', 1.day.ago, self.id])
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
        google = search_positions["Google"]
      rescue
      end
      begin
        bing = search_positions["Bing"]
      rescue
      end
      begin
        yahoo = search_positions["Yahoo"]
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

      self.keyword_rankings.create(:google => google, :bing => bing, :yahoo => yahoo, :cpc => cpc, :relevancy => relevancy)

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

  def get_new_search_positions(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/keyword/position?keyword=' + self.descriptor.gsub(' ', '+') + '&url=' + nickname.gsub('www.', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result'].to_a.first.second
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
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

  def most_recent_google_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    self.most_recent_ranking_between(start_date, end_date).google
  end

  def most_recent_yahoo_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    self.most_recent_ranking_between(start_date, end_date).yahoo
  end

  def most_recent_bing_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    self.most_recent_ranking_between(start_date, end_date).bing
  end


  protected

  def most_recent_ranking_between(start_date, end_date)
    self.keyword_rankings.between(start_date, end_date).last
  end

end
