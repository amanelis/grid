class SemCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_sem_campaigns, :dependent => :destroy
  has_many :sem_campaign_report_statuses, :dependent => :destroy
  
  named_scope :basic, :conditions => {:mobile => false}
  named_scope :mobile, :conditions => {:mobile => true}

  
  # INITIALIZATION
  
  def initialize_thyself
    self.campaign.initialize_thyself
    self.mobile = false if self.mobile.nil?
    self.monthly_budget ||= 0.0
    self.rake ||= 0.0
    self.developer_token ||= ""
    self.application_token ||= ""
    self.user_agent ||= ""
    self.password ||= ""
    self.email ||= ""
    self.client_email ||= ""
    self.environment ||= ""
  end
  

  # INSTANCE BEHAVIOR

  def spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.spend_between(start_date, end_date) }
  end

  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.cost_between(start_date, end_date) }
  end

  def clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.clicks_between(start_date, end_date) }
  end

  def impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.impressions_between(start_date, end_date) }
  end

  def click_through_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (impressions = self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.impressions_between(start_date, end_date) }) > 0 ? (self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.clicks_between(start_date, end_date) })/impressions.to_f : 0.0
  end

  def cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (cost = self.cost_between(start_date, end_date)) > 0 ? self.clicks_between(start_date, end_date) / cost : 0.0
  end

  def average_position_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.google_sem_campaigns.count) > 0 ? self.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.average_position_between(start_date, end_date) } / count : 0.0
  end

  def number_of_visits_by_date
    self.campaign.number_of_visits_by_date
  end

  def number_of_clicks_by_date
    Utilities.merge_and_sum_timeline_data(self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.number_of_clicks_by_date }, :clicks)
  end

  def number_of_impressions_by_date
    Utilities.merge_and_sum_timeline_data(self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.number_of_impressions_by_date }, :impressions)
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

  def combined_timeline_data
    raw_data = Utilities.merge_timeline_data(self.number_of_clicks_by_date, self.number_of_impressions_by_date, self.number_of_leads_by_date)
    Utilities.massage_timeline(raw_data, [:clicks, :impressions, :leads])
  end

  def calls_per_visit_on(date)
    self.campaign.website.website_visits.for_date(date).inject({}) { |data, visit| data[visit] = self.campaign.calls.snapshot(visit.time_of_visit, 60) ; data }
  end

  def percentage_spent_this_month
    (budget = self.monthly_budget).present? && (budget = self.monthly_budget) > 0 ? (self.spend_between(Date.today.beginning_of_month, Date.today.end_of_month) / budget.to_f) * 100 : 0
  end


  # PREDICATES
  
  def valid_channel?
    self.channel.blank? || self.channel.is_sem?
  end

end
