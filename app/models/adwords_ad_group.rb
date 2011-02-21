class AdwordsAdGroup < ActiveRecord::Base
  belongs_to :google_sem_campaign
  has_many :adwords_ads, :dependent => :destroy
  has_many :adwords_keywords, :dependent => :destroy
  has_many :adwords_ad_summaries, :through => :adwords_ads


  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_summaries.between(start_date, end_date).sum(:cost) / 1000000.0
  end

  def clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_summaries.between(start_date, end_date).sum(:clicks)
  end

  def impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_summaries.between(start_date, end_date).sum(:imps)
  end

  def summaries_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_summaries.between(start_date, end_date).count
  end

  def positions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_summaries.between(start_date, end_date).sum(:pos)
  end
  
  def average_quality_score_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_ad_summaries.between(start_date, end_date).count) > 0 ? self.adwords_ad_summaries.between(start_date, end_date).sum(:quality_score).to_f / count : 0.0
  end

  def number_of_clicks_by_date
    self.adwords_ad_summaries.sum(:clicks, :group => "date(summary_date)", :order =>"summary_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:clicks => value}; data }
  end

  def number_of_impressions_by_date
    self.adwords_ad_summaries.sum(:imps, :group => "date(summary_date)", :order =>"summary_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:impressions => value}; data }
  end

end
