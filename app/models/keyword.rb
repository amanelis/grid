require 'digest/sha1'
require 'cgi'

class Keyword < ActiveRecord::Base
  belongs_to :seo_campaign
  has_many :keyword_rankings, :dependent => :destroy


  # MAINTENANCE METHODS
  
  def self.merge_duplicate_keywords
    count = 0
    Keyword.all.each do |keyword|
      keyword_id = ''
      Keyword.all.each do |inner_keyword|
        if inner_keyword.seo_campaign_id == keyword.seo_campaign_id && inner_keyword.descriptor.strip == keyword.descriptor && inner_keyword.id != keyword.id
          inner_keyword.keyword_rankings.each do |ranking|
            ranking.keyword = keyword
            ranking.save!
          end
          inner_keyword.delete
        end
      end
    end
  end

  
  # CLASS BEHAVIOR

  def self.update_keywords_from_salesforce
    job_status = JobStatus.create(:name => "Keyword.update_keywords_from_salesforce")
    begin
      sf_campaigns = Salesforce::Clientcampaign.find_all_by_campaign_type__c('SEO')
      sf_campaigns.each do |sf_campaign|
        local_seo_campaign = Campaign.find_by_salesforce_id(sf_campaign.id).try(:campaign_style)
        if sf_campaign.keywords__c.present? && local_seo_campaign.present?
          keywords = sf_campaign.keywords__c.split(',').collect(&:strip)
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


  # INSTANCE BEHAVIOR

  def most_recent_google_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:google)).present? ? ranking : 0
  end

  def most_recent_yahoo_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:yahoo)).present? ? ranking : 0
  end

  def most_recent_bing_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:bing)).present? ? ranking : 0
  end
  
  def most_recent_google_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:google)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end

  def most_recent_yahoo_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:yahoo)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end

  def most_recent_bing_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:bing)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end

  def google_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.keyword_rankings.between(start_date, end_date)).present? ? ([rankings.first.google, 100].compact.min) - ([rankings.last.google, 100].compact.min) : 0
  end

  def yahoo_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.keyword_rankings.between(start_date, end_date)).present? ? ([rankings.first.yahoo, 100].compact.min) - ([rankings.last.yahoo, 100].compact.min) : 0
  end

  def bing_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.keyword_rankings.between(start_date, end_date)).present? ? ([rankings.first.bing, 100].compact.min) - ([rankings.last.bing, 100].compact.min) : 0
  end
  
  def most_recent_ranking()
    self.keyword_rankings.last
  end
  
  protected

  def most_recent_ranking_between(start_date, end_date)
    self.keyword_rankings.between(start_date, end_date).last
  end

end
