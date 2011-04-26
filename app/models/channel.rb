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
    self.cycle_start_day ||= 1
  end


  # INSTANCE BEHAVIOR
  
  def current_month
    Date.today.day < self.cycle_start_day ? Date.today.month - 1 : Date.today.month
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
    self.rake_for
  end
  
  def current_cost
    self.cost_for(self.current_month)
  end
  
  def budget_for(month = Date.today.month, year = Date.today.year)
    self.base_budget_for(month, year) + self.infusions_for(month, year)
  end
  
  def base_budget_for(month = Date.today.month, year = Date.today.year)
    end_date = Date.civil(year, month, self.cycle_start_day) + 1.month - 1.day
    self.budget_settings.upto(end_date).last.amount
  end
  
  def infusions_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date + 1.month - 1.day
    self.budget_infusions.between(start_date, end_date).to_a.sum(&:amount)
  end
  
  def rake_percentage_for(date = Date.today)
    self.rake_settings.upto(date).last.try(:percentage) || 0
  end
  
  def cost_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date + 1.month - 1.day
    self.campaigns.active.select(&:is_sem?).collect(&:campaign_style).sum { |sem_campaign| sem_campaign.cost_between(start_date, end_date) }
  end

  def spend_for(month = Date.today.month, year = Date.today.year)
    start_date = Date.civil(year, month, self.cycle_start_day)
    end_date = start_date + 1.month - 1.day
    self.campaigns.active.select(&:is_sem?).collect(&:campaign_style).sum { |sem_campaign| sem_campaign.total_spend_between(start_date, end_date) }
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


  # PRIVATE BEHAVRIOR

  private

  def valid_channel_manager
    errors.add(:channel, "has an invalid channel manager") unless self.channel_manager.blank? || self.channel_manager.group_account == self.account.group_account
  end
  
end