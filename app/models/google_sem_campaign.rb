class GoogleSemCampaign < ActiveRecord::Base
  belongs_to :sem_campaign
  has_many :adwords_campaign_summaries, :dependent => :destroy
  has_many :adwords_ad_groups, :dependent => :destroy


  # INSTANCE BEHAVIOR

  def spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (self.cost_between(start_date, end_date) * 100.0) / (100.0 - self.rake)
  end

#  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
#    self.adwords_campaign_summaries.between(start_date, end_date).sum(:cost) / 1000000.0
#  end

  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.cost_between(start_date, end_date) }
  end

  def rake
    (rake = self.sem_campaign.rake).present? ? rake : 0.0
  end

#  def clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
#    self.adwords_campaign_summaries.between(start_date, end_date).sum(:clicks)
#  end

  def clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.clicks_between(start_date, end_date) }
  end

#  def impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
#    self.adwords_campaign_summaries.between(start_date, end_date).sum(:imps)
#  end

  def impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.impressions_between(start_date, end_date) }
  end

  def click_through_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (impressions = self.impressions_between(start_date, end_date)) > 0 ? self.clicks_between(start_date, end_date).to_f / impressions : 0.0
  end

#  def average_position_between(start_date = Date.yesterday, end_date = Date.yesterday)
#    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:pos).to_f / count : 0.0
#  end

  def average_position_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.summaries_between(start_date, end_date) }) > 0 ? self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.positions_between(start_date, end_date) }.to_f / count : 0.0
  end

#  def number_of_clicks_by_date
#    self.adwords_campaign_summaries.sum(:clicks, :group => "date(report_date)", :order =>"report_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:clicks => value}; data }
#  end
#
#  def number_of_impressions_by_date
#    self.adwords_campaign_summaries.sum(:imps, :group => "date(report_date)", :order =>"report_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:impressions => value}; data }
#  end

  def number_of_clicks_by_date
    Utilities.merge_and_sum_timeline_data(self.adwords_ad_groups.collect { |adwords_ad_group| adwords_ad_group.number_of_clicks_by_date }, :clicks)
  end

  def number_of_impressions_by_date
    Utilities.merge_and_sum_timeline_data(self.adwords_ad_groups.collect { |adwords_ad_group| adwords_ad_group.number_of_impressions_by_date }, :impressions)
  end

end
