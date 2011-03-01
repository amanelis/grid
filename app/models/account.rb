class Account < ActiveRecord::Base
  belongs_to :group_account
	belongs_to :reseller, :class_name => "Account", :foreign_key => "reseller_id"
	has_many :basic_channels, :dependent => :destroy
  has_many :campaigns, :dependent => :destroy
  has_many :websites, :through => :campaigns
	has_many :clients, :class_name => "Account", :foreign_key => "reseller_id"
  has_one :adwords_client, :dependent => :destroy
  
  has_many :seo_campaigns, :through => :campaigns, :source => :campaign_style, :source_type => 'SeoCampaign'
  has_many :sem_campaigns, :through => :campaigns, :source => :campaign_style, :source_type => 'SemCampaign'
  has_many :basic_campaigns, :through => :campaigns, :source => :campaign_style, :source_type => 'BasicCampaign'
  
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

  belongs_to :account_manager, :class_name => "GroupUser", :foreign_key => "account_manager_id"
  has_many :account_users
  
  named_scope :active, :conditions => ['LCASE(status) = ?', "active"], :order => "name ASC"
  named_scope :inactive, :conditions => ['LCASE(status) = ?', "inactive"], :order => "name ASC"
  named_scope :reseller, :conditions => ['LCASE(account_type) LIKE ?', "%reseller%"]

  attr_accessor :account_status
  
  validates_uniqueness_of :name, :case_sensitive => false

  
  # CLASS BEHAVIOR

  def self.combined_timeline_data
    raw_data = Utilities.merge_and_sum_timeline_data(self.active.collect { |account| account.number_of_leads_by_date }, :leads)
    Utilities.massage_timeline(raw_data, [:leads])
  end
  
  def self.get_accounts_data
    start_date = Rails.env.development? ? Date.yesterday - 1.day : Date.yesterday.beginning_of_month
    end_date = Date.yesterday
    self.active.inject({}) do |the_data, an_account|
      the_data[an_account.id] = {:name => an_account.name,
                                 :account_type => an_account.account_type,
                                 :ctr => an_account.sem_click_through_rate_between(start_date, end_date) * 100,
                                 :leads => an_account.number_of_total_leads_between(start_date, end_date),
                                 :cpconv => an_account.cost_per_lead_between(start_date, end_date),
                                 :leads_by_day => an_account.number_of_total_leads_by_day_between(start_date, end_date)}
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
    Account.find(:all, :conditions => ['status = ? AND account_type LIKE ?', status, ('%' + account_type + '%')]).sort { |a,b| a.name.downcase <=> b.name.downcase }
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
  
  def self.get_twilio_subaccounts
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts.json?", 'GET').body)['accounts']
  end
  
  def self.get_active_twilio_subaccounts
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts.json?Status=active", 'GET').body)['accounts']
  end
  
  def self.get_suspended_subaccounts
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts.json?Status=suspended", 'GET').body)['accounts']
  end
  
  def self.get_closed_subaccounts
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts.json?Status=closed", 'GET').body)['accounts']
  end
  
  def self.get_all_twilio_numbers
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers.json?", 'GET').body)['incoming_phone_numbers']
  end
  
    
  # INSTANCE BEHAVIOR
  
  def channels
    self.channels.sort!
  end
  
  def send_weekly_report(date = Date.today, previous = self.weekly_report_mtd? ? 0 : 6)
    return if valid_reporting_emails.blank?
    return unless Rails.env.production?
    Notifier.send_later(:deliver_weekly_report, self, self.valid_reporting_emails, date, previous)
    self.update_attribute(:last_weekly_report_sent, DateTime.now)
  end

  def weekly_report_sent_this_week?
    self.last_weekly_report_sent.present? ? self.last_weekly_report_sent.beginning_of_week == DateTime.now.beginning_of_week : false
  end
  
  def weekly_reporting_data(date = Date.today, previous = self.weekly_report_mtd? ? 0 : 6)
    end_date = date - 1.day
    start_date = (previous == 0 ? end_date.beginning_of_month : end_date - previous.days)
    data = {}
    data[:account_name] = self.name
    data[:start_date] = start_date
    data[:end_date] = end_date
    data[:all_calls] = self.number_of_all_calls_for_managed_campaigns_between(start_date, end_date)
    data[:lead_calls] = self.number_of_lead_calls_for_managed_campaigns_between(start_date, end_date)
    data[:all_submissions] = self.number_of_all_submissions_for_managed_campaigns_between(start_date, end_date)
    data[:lead_submissions] = self.number_of_lead_submissions_for_managed_campaigns_between(start_date, end_date)
    if self.account_manager_complete?
      data[:account_manager_name] = self.account_manager.name
      data[:account_manager_phone_number] = self.account_manager.phone_number
      data[:account_manager_email] = self.account_manager.email
    else
      data[:account_manager_name] = "your account manager"
      data[:account_manager_phone_number] = "(210) 691-0100"
      data[:account_manager_email] = "support@cityvoice.com"
    end
    data
  end
  
  def valid_reporting_emails
    (self.reporting_emails || "").split(/, \s*/).select { |email_address| Utilities.is_valid_email_address?(email_address) }
  end
  
  def send_weekly_report_now(date = Date.today, previous = self.weekly_report_mtd? ? 0 : 6)
    return unless self.can_send_weekly_report_now?
    Notifier.deliver_weekly_report(self, self.valid_reporting_emails, date, previous)
    self.update_attribute(:last_weekly_report_sent, DateTime.now)
  end
  
  def can_send_weekly_report_now?
    self == Account.find_by_name("CityVoice")
  end
  
  def send_test_weekly_report(email_list, date = Date.today, previous = 0)
    return if email_list.blank?
    Notifier.deliver_weekly_report(self, email_list, date, previous, [])
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

  def number_of_all_calls_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_all_calls_between(start_date, end_date) }
  end

  def number_of_all_calls_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_all_calls_between(start_date, end_date) }
  end

  def number_of_lead_calls_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_lead_calls_between(start_date, end_date) }
  end

  def number_of_lead_calls_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_lead_calls_between(start_date, end_date) }
  end

  def number_of_all_submissions_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_all_submissions_between(start_date, end_date) }
  end

  def number_of_all_submissions_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_all_submissions_between(start_date, end_date) }
  end

  def number_of_lead_submissions_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_lead_submissions_between(start_date, end_date) }
  end

  def number_of_lead_submissions_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_lead_submissions_between(start_date, end_date) }
  end

  def sem_cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (spend = self.sem_spend_between(start_date, end_date)) > 0 ? self.sem_clicks_between(start_date, end_date) / spend : 0.0
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

  def total_revenue_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.total_revenue_between(start_date, end_date) }
  end
  
  def total_revenue_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.total_revenue_between(start_date, end_date) }
  end
  
  def number_of_total_leads_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def number_of_total_leads_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def number_of_total_contacts_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_total_contacts_between(start_date, end_date) }
  end

  def number_of_total_contacts_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.number_of_total_contacts_between(start_date, end_date) }
  end

  def number_of_total_leads_by_day_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (start_date..end_date).inject([]) { |data, date | data << self.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) } }
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
  
  def true_cost_per_lead_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.cost_between(start_date, end_date) / total_leads : 0.0
  end

  def true_cost_per_contact_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_contacts = self.number_of_total_contacts_between(start_date, end_date)) > 0 ? self.cost_between(start_date, end_date) / total_contacts : 0.0
  end

  def spend_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end
  
  def cost_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end
  
  def total_cost_per_lead_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.cost_per_lead_between(start_date, end_date) }
  end

  def total_cost_per_contact_for_managed_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.managed.to_a.sum { |campaign| campaign.cost_per_contact_between(start_date, end_date) }
  end

  def spend_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end
  
  def cost_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def total_cost_per_lead_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.cost_per_lead_between(start_date, end_date) }
  end

  def total_cost_per_contact_for_unmanaged_campaigns_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.unmanaged.to_a.sum { |campaign| campaign.cost_per_contact_between(start_date, end_date) }
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
  
  def create_twilio_subaccount
    resp = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts.json?", 'POST', {'FriendlyName' => self.name})
    raise unless resp.kind_of? Net::HTTPSuccess
    self.update_attribute(:twilio_id, JSON.parse(resp.body)['sid'])
  end
  
  def get_twilio_subaccount
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}.json?", 'GET').body)
  end
  
  def get_twilio_subaccount_status
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}.json?", 'GET').body)['status']
  end
  
  def get_subaccount_twilio_numbers
    JSON.parse(Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}/IncomingPhoneNumbers.json?", 'GET').body)['incoming_phone_numbers']
  end
  
  def suspend_twilio_subaccount
    raise unless Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}.json?", 'POST', {'Status' => 'suspended'}).kind_of? Net::HTTPSuccess
  end
  
  def activate_twilio_subaccount
    raise unless Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}.json?", 'POST', {'Status' => 'active'}).kind_of? Net::HTTPSuccess
  end
  
  def close_twilio_subaccount
    raise unless Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.twilio_id}.json?", 'POST', {'Status' => 'closed'}).kind_of? Net::HTTPSuccess
  end
  
  def create_campaign(channel, name)
    #if flavor.include? 'SEM'
    #  new_campaign = SemCampaign.new
    #  new_campaign.flavor = flavor
    #elsif flavor.include? 'SEO'
    #  new_campaign = SeoCampaign.new 
    #  new_campaign.flavor = flavor
    #elsif flavor.include? 'Maps'
    #  new_campaign = MapsCampaign.new 
    #  new_campaign.flavor = flavor
    #else
    
    new_campaign = OtherCampaign.new
    new_campaign.flavor = flavor
    #end

    new_campaign.account = self
    new_campaign.name = name
    new_campaign.status = 'Active'
    new_campaign.save
    
    new_campaign.campaign
  end
  
  
  # PREDICATES
  
  def active?
    self.status.downcase == "active"
  end
  
  def account_type?(type)
    self.account_type.split(';').include?(type)
  end
  
  def account_manager_complete?
    return false unless self.account_manager.present?
    return false unless self.account_manager.name.present?
    return false unless self.account_manager.phone_number.present?
    return false unless self.account_manager.email.present?
    true
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
