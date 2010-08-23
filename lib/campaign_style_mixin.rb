module CampaignStyleMixin

  def self.included(base)
    base.class_eval do
      has_one :campaign, :as => :campaign_style
      delegate :account, :phone_numbers, :contact_forms, :websites, :status, :name, :target_cities, :to => :campaign
      accepts_nested_attributes_for :campaign
    end
  end

end