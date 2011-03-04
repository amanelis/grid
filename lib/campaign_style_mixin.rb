module CampaignStyleMixin

  def self.included(base)
    base.class_eval do
      has_one :campaign, :as => :campaign_style, :dependent => :destroy
      delegate :account, :account=, :phone_numbers, :calls, :contact_forms, :submissions, :website, :website=, :status, :status=, :name, :name= ,:zip_code, :zip_code=, :target_cities, :target_cities=, :flavor, :flavor=, :salesforce_id, :salesforce_id=, :industries, :to => :campaign
      accepts_nested_attributes_for :campaign
    end
  end

  def initialize(attributes={})
    self.campaign = Campaign.new
    super(attributes)
    # self.initialize_specifics(attributes)
    self
  end

end