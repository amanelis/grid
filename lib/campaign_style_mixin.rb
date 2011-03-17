module CampaignStyleMixin

  def self.included(base)
    base.class_eval do
      has_one :campaign, :as => :campaign_style, :dependent => :destroy
      delegate :account, :account=, :channel, :channel=, :phone_numbers, :calls, :contact_forms, :submissions, :website, :website=, :status, :status=, :name, :name= ,:zip_code, :zip_code=, :target_cities, :target_cities=, :flavor, :flavor=, :salesforce_id, :salesforce_id=, :industries, :time_zone, :to => :campaign
      accepts_nested_attributes_for :campaign
    end
  end

  # INITIALIZATION
  
  def after_initialize
    return unless self.new_record?
    self.campaign ||= Campaign.new
    self.campaign.campaign_style ||= self
    self.initialize_thyself
  end

end