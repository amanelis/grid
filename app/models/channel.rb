class Channel < ActiveRecord::Base
  belongs_to :account
  belongs_to :channel_manager, :class_name => "GroupUser", :foreign_key => "channel_manager_id"
  has_many :campaigns
  has_many :budget_settings, :dependent => :destroy
  has_many :rake_settings, :dependent => :destroy
  has_many :budget_infusions, :dependent => :destroy

  validates_presence_of :name, :channel_type
  validates_uniqueness_of :name, :case_sensitive => false, :scope => "account_id"
  
  SEO = "seo"
  SEM = "sem"
  BASIC = "basic"

  CHANNEL_TYPES = [SEO, SEM, BASIC]
  CHANNEL_TYPE_OPTIONS = [['SEO Channel', SEO], ['SEM Channel', SEM], ['Basic Channel', BASIC]].to_ordered_hash

  DEFAULT_SEO_CHANNEL_NAME = "Website"
  DEFAULT_SEM_CHANNEL_NAME = "Adwords"
  DEFAULT_BASIC_CHANNEL_NAME = "Basic"

  validates_inclusion_of :channel_type, :in => CHANNEL_TYPES
  validates_numericality_of :cycle_start_day, :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 28, :message => "must be an integer between 1 and 28"
  validate :valid_channel_manager


  # CLASS BEHAVIOR

  def self.build_default_seo_channel_for(account)
    existing_channel = account.default_seo_channel
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_SEO_CHANNEL_NAME
    new_channel.set_type_seo
    new_channel.save!
    new_channel
  end

  def self.build_default_sem_channel_for(account)
    existing_channel = account.default_sem_channel
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_SEM_CHANNEL_NAME
    new_channel.set_type_sem
    new_channel.save!
    new_channel
  end

  def self.build_default_basic_channel_for(account)
    existing_channel = account.default_basic_channel
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_BASIC_CHANNEL_NAME
    new_channel.set_type_basic
    new_channel.save!
    new_channel
  end
  
  def self.default_seo_channel_for(account)
    account.channels.detect { |channel| channel.name == DEFAULT_SEO_CHANNEL_NAME }
  end

  def self.default_sem_channel_for(account)
    account.channels.detect { |channel| channel.name == DEFAULT_SEM_CHANNEL_NAME }
  end

  def self.default_basic_channel_for(account)
    account.channels.detect { |channel| channel.name == DEFAULT_BASIC_CHANNEL_NAME }
  end


  # INITIALIZATION
  
  def after_initialize
    self.cycle_start_day ||= 1 if attributes.has_key?('cycle_start_day')
  end


  # INSTANCE BEHAVIOR
  
  def current_month
    Date.today.day < self.cycle_start_day ? Date.today.prev_month.month : Date.today.month
  end
  
  def previous_month
    Date.today.day < self.cycle_start_day ? Date.today.prev_month.prev_month.month : Date.today.prev_month.month
  end
  
  def current_start_date
    Date.civil(Date.today.year, self.current_month, self.cycle_start_day)
  end
  
  def current_end_date
    self.current_start_date.next_month.yesterday
  end
  
  def current_cycle_length
    self.cycle_length_for(self.current_month)
  end
  
  def cycle_length_for(month = Date.today.month, year = Date.today.year)
    Date.civil(year, month, -1).day
  end
  
  def budget_target_variance
    self.days_left_in_cycle - self.number_of_days_money_remaining
  end
  
  def number_of_days_money_remaining
    (current_cost = self.current_cost) == 0.0 ? self.current_cycle_length : (self.current_amount_remaining / (current_cost / self.days_into_cycle))
  end
  
  def days_left_in_cycle(date = Date.today)
    self.cycle_length_for((date.day < self.cycle_start_day ? date.prev_month.month : date.month), date.year) - self.days_into_cycle(date)
  end
  
  def days_into_cycle(date = Date.today)
    (Date.civil(date.year, (date.day < self.cycle_start_day ? date.prev_month.month : date.month), self.cycle_start_day)..date).count
  end
  
  def current_percentage_of_money_used
    self.percentage_of_money_used_for(self.current_month)
  end
  
  def current_amount_remaining
    self.amount_remaining_for(self.current_month)
  end
  
  def current_spend_budget
    self.spend_budget_for(self.current_month)
  end
  
  def current_budget
    self.budget_for(self.current_month)
  end
  
  def current_base_budget
    self.base_budget_for(self.current_month)
  end
  
  def current_infusions
    self.infusions_for(self.current_month)
  end
  
  def current_rake_percentage
    self.rake_percentage_for(self.current_month)
  end
  
  def current_cost
    self.cost_for(self.current_month)
  end
  
  def current_clicks
    self.clicks_for(self.current_month)
  end
  
  def current_impressions
    self.impressions_for(self.current_month)
  end
  
  def current_click_through_rate
    self.click_through_rate_for(self.current_month)
  end
  
  def current_cost_per_click
    self.cost_per_click_for(self.current_month)
  end
  
  def current_average_position
    self.average_position_for(self.current_month)
  end
  
  def current_total_leads
    self.total_leads_for(self.current_month)
  end
  
  def current_conversion_rate
    self.conversion_rate_for(self.current_month)
  end
  
  def current_weighted_cost_per_lead
    self.weighted_cost_per_lead_for(self.current_month)
  end
  
  def previous_conversion_rate
    self.conversion_rate_for(self.previous_month)
  end
  
  def previous_weighted_cost_per_lead
    self.weighted_cost_per_lead_for(self.previous_month)
  end
  
  def percentage_of_money_used_for(month = Date.today.month, year = Date.today.year)    
    (spend_budget = self.spend_budget_for(month, year)) == 0.0 ? 0 : 100.0 * self.cost_for(month, year) / spend_budget
  end
  
  def amount_remaining_for(month = Date.today.month, year = Date.today.year)
    self.spend_budget_for(month, year) - self.cost_for(month, year)
  end
  
  def spend_budget_for(month = Date.today.month, year = Date.today.year)
    self.budget_for(month, year) * ((100 - self.rake_percentage_for(month, year)) / 100.0)
  end
  
  def budget_for(month = Date.today.month, year = Date.today.year)
    self.base_budget_amount_for(month, year) + self.infusion_amount_for(month, year)
  end
  
  def base_budget_amount_for(month = Date.today.month, year = Date.today.year)
    self.base_budget_for(month, year).try(:amount) || 0.0
  end
  
  def base_budget_start_date_for(month = Date.today.month, year = Date.today.year)
    self.base_budget_for(month, year).stat_date
  end
  
  def base_budget_for(month = Date.today.month, year = Date.today.year)
    self.budget_settings.upto(Date.civil(year, month, self.cycle_start_day).next_month.yesterday).last
  end
  
  def infusion_amount_for(month = Date.today.month, year = Date.today.year)
    self.infusions_for(month, year).sum(&:amount)
  end
  
  def infusions_for(month = Date.today.month, year = Date.today.year)
    self.budget_infusions.between(start_date = Date.civil(year, month, self.cycle_start_day), start_date.next_month.yesterday).to_a
  end
  
  def rake_percentage_for(month = Date.today.month, year = Date.today.year)
    self.rake_setting_for(month, year).try(:percentage) || 0
  end
  
  def rake_start_date_for(month = Date.today.month, year = Date.today.year)
    self.rake_setting_for(month, year).try(:start_date)
  end
  
  def rake_setting_for(month = Date.today.month, year = Date.today.year)
    self.rake_settings.upto(Date.civil(year, month, self.cycle_start_day).next_month.yesterday).last
  end
  
  def rake_setting_on(date = Date.today)
    self.rake_settings.upto(date).last.try(:percentage) || 0
  end
  
  def cost_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date.next_month.yesterday
    self.campaigns.active.sem.collect(&:campaign_style).sum { |sem_campaign| sem_campaign.cost_between(start_date, end_date) }
  end

  def spend_for(month = Date.today.month, year = Date.today.year)
    (self.cost_for(month, year) * 100.0) / (100.0 - self.rake_percentage_for(month, year))
  end

  def clicks_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date.next_month.yesterday
    self.campaigns.active.sem.collect(&:campaign_style).sum { |sem_campaign| sem_campaign.clicks_between(start_date, end_date) }
  end

  def impressions_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date.next_month.yesterday
    self.campaigns.active.sem.collect(&:campaign_style).sum { |sem_campaign| sem_campaign.impressions_between(start_date, end_date) }
  end
  
  def click_through_rate_for(month = Date.today.month, year = Date.today.year)
    (impressions = self.impressions_for(month, year)) > 0 ? self.clicks_for(month, year) / impressions.to_f : 0.0
  end
  
  def cost_per_click_for(month = Date.today.month, year = Date.today.year)
    (clicks = self.clicks_for(month, year)) > 0 ? self.cost_for(month, year) / clicks.to_f : 0.0
  end
  
  def average_position_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date.next_month.yesterday
    sem_campaigns = self.campaigns.active.sem.collect(&:campaign_style)
    (count = sem_campaigns.sum { |sem_campaign| sem_campaign.google_sem_campaigns.count }) > 0 ? sem_campaigns.sum { |sem_campaign| sem_campaign.google_sem_campaigns.to_a.sum { |google_sem_campaign| google_sem_campaign.average_position_between(start_date, end_date) } } / count : 0.0
  end
  
  def total_leads_for(month = Date.today.month, year = Date.today.year)
    self.number_of_total_leads_between(start_date = Date.civil(year, month, self.cycle_start_day), start_date.next_month.yesterday)
  end
  
  def conversion_rate_for(month = Date.today.month, year = Date.today.year)
    (clicks = self.clicks_for(month, year)) > 0 ? self.total_leads_for(month, year) / clicks.to_f : 0.0
  end
  
  def weighted_cost_per_lead_for(month = Date.today.month, year = Date.today.year)
    self.weighted_cost_per_lead_between(start_date = Date.civil(year, month, self.cycle_start_day), start_date.next_month.yesterday)
  end

  def number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end
  
  def weighted_cost_per_lead_between(start_date = Date.yesterday, end_date = Date.yesterday)
    Campaign.weighted_cost_per_lead_for(self.campaigns.active.to_a, start_date, end_date)
  end

  def channel_manager_name
    self.valid_channel_manager_information? ? self.channel_manager.name : "your channel manager"
  end
  
  def channel_manager_phone_number
    self.valid_channel_manager_information? ? self.channel_manager.phone_number : "(210) 691-0100"
  end
  
  def channel_manager_email
    self.valid_channel_manager_information? ? self.channel_manager.email : "support@cityvoice.com"
  end

  def set_type_seo
    self.channel_type = SEO
  end

  def set_type_sem
    self.channel_type = SEM
  end

  def set_type_basic
    self.channel_type = BASIC
  end


  # PREDICATES

  def is_seo?
    self.channel_type == SEO
  end

  def is_sem?
    self.channel_type == SEM
  end

  def is_basic?
    self.channel_type == BASIC
  end

  def valid_channel_manager_information?
    self.channel_manager.try(:valid_channel_manager_information?).to_boolean
  end
  
  def is_virgin?
    self.budget_settings.blank? && self.rake_settings.blank?
  end
  
  def editable_date?(date)
    return true if date >= Date.today
    (date.beginning_of_month == Date.today.beginning_of_month) && (([Date.today.day, date.day].max < self.cycle_start_day) || ([Date.today.day, date.day].min >= self.cycle_start_day))
  end
  

  # PRIVATE BEHAVRIOR

  private

  def valid_channel_manager
    errors.add(:channel, "has an invalid channel manager") unless self.channel_manager.blank? || self.channel_manager.group_account == self.account.group_account
  end
  
end