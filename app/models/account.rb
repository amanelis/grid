class Account < ActiveRecord::Base
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
  
  named_scope :active, :conditions => ['LCASE(status) = ? OR LCASE(status) = ?', "active", "paused"], :order => "name ASC"
  named_scope :inactive, :conditions => ['LCASE(status) = ?', "inactive"], :order => "name ASC"
  named_scope :reseller, :conditions => ['LCASE(account_type) LIKE ?', "%reseller%"]

  attr_accessor :account_status
  
  validates_uniqueness_of :name, :case_sensitive => false
  
  # CLASS BEHAVIOR

  def self.pull_all_data_migrations
    puts "Pulling Salesforce Accounts..."
    Account.pull_salesforce_accounts
    puts "Pulling Salesforce Campaigns..."
    Campaign.pull_salesforce_campaigns
    puts "Pulling Marchex Phone Numbers..."
    PhoneNumber.get_marchex_numbers
    puts "Updating Calls..."
    Call.update_calls
    puts "Adding Websites..."
    Website.add_websites
    puts "Updating Website Visits..."
    WebsiteVisit.data_pull_websites_visits
    puts "Pulling Salesforce Keywords..."
    Keyword.update_keywords_from_salesforce
    puts "Updating Keyword Rankings..."
    Keyword.update_keyword_rankings
    puts "Updating Inbound Links"
    SeoCampaign.update_inbound_links
    puts "Cleaning Inbound Links"
    SeoCampaign.clean_up_inbound_links
    puts "Updating Website Analyses"
    SeoCampaign.update_website_analyses
    puts "Updating Map Keywords"
    MapKeyword.update_keywords_from_salesforce
    puts "Updating Map Keyword Rankings"
    MapKeyword.update_map_rankings
    puts 'Updating Adwords Campaign Level Reports'
    SemCampaign.update_sem_campaign_reports_by_campaign
    puts 'Updating Adwords Ad Level Reports'
    SemCampaign.update_sem_campaign_reports_by_ad
    puts 'Updating Campaign.target_cities'
    Campaign.fix_target_cities
    puts "Done."
  end

  def self.pull_salesforce_accounts
    job_status = JobStatus.create(:name => "Account.pull_salesforce_accounts")
    begin
      cityvoice_account = Account.find_by_name("CityVoice")
      sf_accounts = Salesforce::Account.find(:all, :conditions => ['account_status__c != ?', ''])
      sf_accounts.each do |sf_account|
        existing_account = Account.find_by_salesforce_id(sf_account.id)
        if existing_account.blank?
          existing_account = Account.new
          existing_account.salesforce_id = sf_account.id
          existing_account.time_zone = "Central Time (US & Canada)"
        end
        existing_account.account_type = sf_account.account_type__c
        existing_account.status = sf_account.account_status__c
        existing_account.name = sf_account.name
        existing_account.street = sf_account.billing_street
        existing_account.city = sf_account.billing_city
        existing_account.county = sf_account.county__c
        existing_account.state = sf_account.billing_state
        existing_account.postal_code = sf_account.billing_postal_code
        existing_account.country = sf_account.billing_country
        existing_account.phone = sf_account.phone
        existing_account.other_phone = sf_account.other_phone_number__c
        existing_account.fax = sf_account.fax
        existing_account.metro_area = sf_account.metro_area__c
        existing_account.website = sf_account.website
        existing_account.industry = sf_account.industry
        existing_account.main_contact = sf_account.main_contact__c
        existing_account.receive_weekly_report = sf_account.receive_weekly_report__c
        existing_account.reporting_emails = sf_account.email_reports_to__c
        
        reseller = sf_account.parent_id.present? ? Account.find_by_salesforce_id(sf_account.parent_id) : cityvoice_account
        existing_account.reseller_id = reseller.id if reseller.present?
        
        existing_account.save
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

#  def self.combined_timeline_data
#    raw_data = Utilities.merge_and_sum_timeline_data(Account.all.collect { |account| account.number_of_visits_by_date }, :visits)
#    Utilities.massage_timeline(raw_data, [:visits])
#  end

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
  
  def self.account_types
    Account.all.collect(&:account_type).compact.join(';').split(';').uniq.sort
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
    exception = self.send_weekly_reports_to(self.accounts_receiving_weekly_reports.reject { |account| account.weeky_report_sent_this_week? })
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
  end

  def self.accounts_receiving_weekly_reports
    self.active.to_a.select { |account| account.receive_weekly_report? && account.reporting_emails.present? }
  end
  
    
  # INSTANCE BEHAVIOR
  
  def send_weekly_report(date = Date.today.beginning_of_week)
    Notifier.send_later(:deliver_weekly_report, self, nil, date)
  end

  def weeky_report_sent_this_week?
    self.last_weekly_report_sent.present? ? self.last_weekly_report_sent.beginning_of_week == DateTime.now.beginning_of_week : false
  end
  
  def previous_days_report_data(date = Date.today.beginning_of_week, previous = 7)
    end_date = date - 1.day
    start_date = end_date - previous.days
    [self.number_of_all_calls_between(start_date, end_date), self.number_of_lead_calls_between(start_date, end_date), self.number_of_all_submissions_between(start_date, end_date), self.number_of_lead_submissions_between(start_date, end_date)]
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
  
  
  # PRIVATE BEHAVRIOR
  
  private
  
  def self.send_weekly_reports_to(accounts)
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
