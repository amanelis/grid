class Channel < ActiveRecord::Base
  belongs_to :account
  has_many :campaigns

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


  # CLASS BEHAVIOR

  def self.build_default_seo_channel_for(account)
    existing_channel = account.channels.detect { |channel| channel.name == DEFAULT_SEO_CHANNEL_NAME }
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_SEO_CHANNEL_NAME
    new_channel.set_type_seo
    new_channel.save!
    new_channel
  end

  def self.build_default_sem_channel_for(account)
    existing_channel = account.channels.detect { |channel| channel.name == DEFAULT_SEM_CHANNEL_NAME }
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_SEM_CHANNEL_NAME
    new_channel.set_type_sem
    new_channel.save!
    new_channel
  end

  def self.build_default_basic_channel_for(account)
    existing_channel = account.channels.detect { |channel| channel.name == DEFAULT_BASIC_CHANNEL_NAME }
    return existing_channel if existing_channel.present?
    new_channel = self.new
    new_channel.account = account
    new_channel.name = DEFAULT_BASIC_CHANNEL_NAME
    new_channel.set_type_basic
    new_channel.save!
    new_channel
  end


  # INSTANCE BEHAVIOR
  
  def number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end
  
  def weighted_cost_per_lead_for(start_date = Date.yesterday, end_date = Date.yesterday)
    Campaign.weighted_cost_per_lead_for(self.campaigns.to_a, start_date, end_date)
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
end