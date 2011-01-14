class Account < ActiveRecord::Base
  belongs_to :group_account
	belongs_to :reseller, :class_name => "Account", :foreign_key => "reseller_id"
  has_many :campaigns, :dependent => :destroy
	has_many :clients, :class_name => "Account", :foreign_key => "reseller_id"
  has_one :adwords_client, :dependent => :destroy
  
  has_many :phone_numbers, :through => :campaigns do
    def calls
      @calls ||= Call.find_all_by_phone_number_id(self.collect(&:id))
    end
  end
	
  has_many :contact_forms, :through => :campaigns do
    def submissions
      @submissions ||= Submission.find_all_by_contact_form_id(self.collect(&:id))
    end
  end

  belongs_to :account_manager
  has_many :account_users
  
  named_scope :active, :conditions => ['LCASE(status) = ? OR LCASE(status) = ? OR LCASE(status) = ?', "active", "paused", "pending setup"], :order => "name ASC"
  named_scope :inactive, :conditions => ['LCASE(status) = ?', "inactive"], :order => "name ASC"
  named_scope :reseller, :conditions => ['LCASE(account_type) LIKE ?', "%reseller%"]

  attr_accessor :account_status
  
  validates_uniqueness_of :name, :case_sensitive => false

  
  # CLASS BEHAVIOR

  def self.cache_results_for_accounts
    Rails.cache.write("admin_data", self.combined_timeline_data)
    Rails.cache.write("accounts_data", self.get_accounts_data)
  end

  def self.combined_timeline_data
    raw_data = Utilities.merge_and_sum_timeline_data(self.active.collect { |account| account.number_of_leads_by_date }, :leads)
    Utilities.massage_timeline(raw_data, [:leads])
  end

  def self.get_accounts_data
    self.active.inject({}) do |the_data, an_account|
      the_data[an_account.id] = {:name => an_account.name,
                                 :account_type => an_account.account_type,
                                 :ctr => an_account.sem_click_through_rate_between(Date.yesterday - 1.week, Date.yesterday) * 100,
                                 :leads => an_account.number_of_total_leads_between(Date.yesterday - 1.week, Date.yesterday),
                                 :cpconv => an_account.cost_per_lead_between(Date.yesterday - 1.week, Date.yesterday),
                                 :leads_by_day => an_account.number_of_total_leads_by_day_between(Date.yesterday - 1.week, Date.yesterday)}
      the_data
    end
  end

  def self.leads_in_previous_hours(time = nil)
    Activity.previous_hours(time).collect { |activity| activity.activity_type }
  end

  def self.account_statuses
    Account.all.collect(&:status).compact.uniq
  end
  
  def self.account_statuses_for(accounts)
    accounts.collect(&:status).compact.uniq
  end
  
  def self.account_types
    Account.all.collect(&:account_type).compact.join(';').split(';').uniq.sort
  end

  def self.account_types_for(accounts)
    accounts.collect(&:account_type).compact.join(';').split(';').uniq.sort
  end

  def self.get_accounts_by_status_and_account_type(status, account_type)
    Account.find(:all, :conditions => ['status = ? AND account_type LIKE ?', status, ('%' + account_type + '%')]).sort! { |a,b| a.name.downcase <=> b.name.downcase }
  end
  
  def self.send_weekly_reports
    job_status = JobStatus.create(:name => "Account.send_weekly_reports")
    exception = self.send_weekly_reports_to(self.accounts_receiving_weekly_reports)
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
  end

  def self.resend_weekly_reports
    job_status = JobStatus.create(:name => "Account.resend_weekly_reports")
    exception = self.send_weekly_reports_to(self.accounts_receiving_weekly_reports.reject { |account| account.weekly_report_sent_this_week? })
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
  end

  def self.accounts_receiving_weekly_reports
    self.active.to_a.select { |account| account.receive_weekly_report? && account.valid_reporting_emails.present? }
  end
  
    
  # INSTANCE BEHAVIOR
  
  def send_weekly_report(date = Date.today.beginning_of_week, previous = 6)
    return if valid_reporting_emails.blank?
    Notifier.send_later(:deliver_weekly_report, self, self.valid_reporting_emails, date, previous)
    self.update_attribute(:last_weekly_report_sent, DateTime.now)
  end

  def weekly_report_sent_this_week?
    self.last_weekly_report_sent.present? ? self.last_weekly_report_sent.beginning_of_week == DateTime.now.beginning_of_week : false
  end
  
  def previous_days_report_data(date = Date.today, previous = 6)
    end_date = date - 1.day
    start_date = (previous == 0 ? end_date.beginning_of_month : end_date - previous.days)
    [self.number_of_all_calls_for_cityvoice_campaigns_between(start_date, end_date), self.number_of_lead_calls_for_cityvoice_campaigns_between(start_date, end_date), self.number_of_all_submissions_for_cityvoice_campaigns_between(start_date, end_date), self.number_of_lead_submissions_for_cityvoice_campaigns_between(start_date, end_date), start_date, end_date, self.name]
  end
  
  def valid_reporting_emails
    (self.reporting_emails || "").split(/, \s*/).select { |email_address| Utilities.is_valid_email_address?(email_address) }
  end
  
  def send_weekly_report_now(date = Date.today.beginning_of_week, previous = 6)
    return unless self.can_send_weekly_report_now?
    Notifier.deliver_weekly_report(self, self.valid_reporting_emails, date, previous)
    self.update_attribute(:last_weekly_report_sent, DateTime.now)
  end
  
  def can_send_weekly_report_now?
    self == Account.find_by_name("CityVoice")
  end
  
  def number_of_visits_by_date
    Utilities.merge_and_sum_timeline_data(self.campaigns.active.collect { |campaign| campaign.campaign_style.number_of_visits_by_date }, :visits)
  end

  def number_of_leads_by_date
    Utilities.merge_and_sum_timeline_data(self.campaigns.active.collect { |campaign| campaign.campaign_style.number_of_leads_by_date }, :leads)
  end

  def combined_timeline_data
    raw_data = Utilities.merge_timeline_data(self.number_of_leads_by_date, self.number_of_visits_by_date)
    Utilities.massage_timeline(raw_data, [:leads, :visits])
  end

  def campaign_seo_combined_timeline_data
    self.campaigns.active.seo.collect { |campaign| campaign.campaign_style.combined_timeline_data }
  end

  def campaign_sem_combined_timeline_data
    self.campaigns.active.sem.collect { |campaign| campaign.campaign_style.combined_timeline_data }
  end

  def campaign_map_combined_timeline_data
    self.campaigns.active.map.collect { |campaign| campaign.campaign_style.combined_timeline_data }
  end

  def sem_number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.sem.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def sem_clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.sem.to_a.sum { |campaign| campaign.campaign_style.clicks_between(start_date, end_date) }
  end

  def sem_impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.sem.to_a.sum { |campaign| campaign.campaign_style.impressions_between(start_date, end_date) }
  end

  def sem_click_through_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (impressions = self.campaigns.active.sem.to_a.sum { |campaign| campaign.campaign_style.impressions_between(start_date, end_date) }) > 0 ? self.campaigns.active.sem.to_a.sum { |campaign| campaign.campaign_style.clicks_between(start_date, end_date) } / impressions.to_f : 0.0
  end

  def sem_average_position_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.campaigns.active.sem.count) > 0 ? self.campaigns.active.sem.to_a.sum { |campaign| campaign.campaign_style.average_position_between(start_date, end_date) } / count : 0.0
  end

  def sem_spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.sem.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def sem_cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.sem.to_a.sum { |campaign| campaign.cost_between(start_date, end_date) }
  end

  def seo_spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def seo_number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def seo_number_of_actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.number_of_actions_between(start_date, end_date) }
  end

  def seo_number_of_average_actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.number_of_average_actions_between(start_date, end_date) }
  end

  def seo_number_of_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.number_of_visits_between(start_date, end_date) }
  end

  def seo_total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.total_time_spent_between(start_date, end_date) }
  end

  def seo_average_total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.average_total_time_spent_between(start_date, end_date) }
  end

  def seo_number_of_bounces_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.seo.to_a.sum { |campaign| campaign.number_of_bounces_between(start_date, end_date) }
  end

  def seo_bounce_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.seo_number_of_visits_between(start_date, end_date)) > 0 ? self.seo_number_of_bounces_between(start_date, end_date).to_f / visits : 0.0
  end

  def maps_number_of_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.maps.to_a.sum { |campaign| campaign.number_of_map_visits_between(start_date, end_date) }
  end

  def number_of_all_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_all_calls_between(start_date, end_date) }
  end

  def number_of_lead_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_lead_calls_between(start_date, end_date) }
  end

  def number_of_all_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_all_submissions_between(start_date, end_date) }
  end

  def number_of_lead_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_lead_submissions_between(start_date, end_date) }
  end

  def number_of_all_calls_for_cityvoice_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.cityvoice.to_a.sum { |campaign| campaign.number_of_all_calls_between(start_date, end_date) }
  end

  def number_of_lead_calls_for_cityvoice_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.cityvoice.to_a.sum { |campaign| campaign.number_of_lead_calls_between(start_date, end_date) }
  end

  def number_of_all_submissions_for_cityvoice_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.cityvoice.to_a.sum { |campaign| campaign.number_of_all_submissions_between(start_date, end_date) }
  end

  def number_of_lead_submissions_for_cityvoice_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.cityvoice.to_a.sum { |campaign| campaign.number_of_lead_submissions_between(start_date, end_date) }
  end

  def sem_cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (spend = self.sem_spend_between(start_date, end_date)) > 0 ? self.sem_clicks_between(start_date, end_date)/spend : 0.0
  end

  def total_spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.sem_cost_between(start_date, end_date) + self.sem_spend_between(start_date, end_date)
  end
  
  def total_revenue_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.total_revenue_between(start_date, end_date) }
  end
  
  def number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def number_of_total_contacts_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_contacts_between(start_date, end_date) }
  end

  def number_of_total_leads_by_day_between(start_date = Date.yesterday, end_date = Date.yesterday)
    data = []
    start_date.upto(end_date) do |date|
      data << self.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) }
    end
    data
  end

  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.cost_between(start_date, end_date) }
  end

  def spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def cost_per_lead_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_leads : 0.0
  end

  def cost_per_contact_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_contacts = self.number_of_total_contacts_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_contacts : 0.0
  end

  # NOTE...these methods don't really make sense at this level in the hierarchy.

  def number_of_answered_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_answered_calls_between(start_date, end_date) }
  end

  def number_of_canceled_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_canceled_calls_between(start_date, end_date) }
  end

  def number_of_voicemail_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_voicemail_calls_between(start_date, end_date) }
  end

  def number_of_other_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_other_calls_between(start_date, end_date) }
  end
  
  
  # PREDICATES
  
  def active?
    ["active", "paused", "pending setup"].include?(self.status.downcase)
  end
  
  def account_type?(type)
    self.account_type.split(';').include?(type)
  end
  
  
  # PRIVATE BEHAVRIOR
  
  private
  
  def self.send_weekly_reports_to(accounts)
    exception = nil
    accounts.each do |account|
      begin
        account.send_weekly_report
      rescue Exception => ex
        exception = ex
        next
      end
    end
    exception
  end
  
end
