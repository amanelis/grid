class GoogleSemCampaign < ActiveRecord::Base
  belongs_to :sem_campaign
  has_many :adwords_campaign_summaries
  has_many :adwords_ad_groups


  # INSTANCE BEHAVIOR

  def spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (self.cost_between(start_date, end_date) * 100.0) / (100.0 - self.rake)
  end

  def cost_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:cost) / 1000000.0
  end

  def rake
    (rake = self.sem_campaign.rake).present? ? rake : 0.0
  end

  def clicks_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:clicks)
  end

  def impressions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:imps)
  end

  def click_through_rate_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (impressions = self.impressions_between(start_date, end_date)) > 0 ? self.clicks_between(start_date, end_date).to_f / impressions : 0.0
  end

  def average_position_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:pos).to_f / count : 0.0
  end

  def number_of_clicks_by_date
    self.adwords_campaign_summaries.sum(:clicks, :group => "date(report_date)", :order =>"report_date ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:clicks => value} ; data}
  end

  def number_of_impressions_by_date
    self.adwords_campaign_summaries.sum(:imps, :group => "date(report_date)", :order =>"report_date ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:impressions => value} ; data}
  end

end
