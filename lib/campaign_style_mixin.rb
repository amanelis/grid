module CampaignStyleMixin

  def self.included(base)
    base.class_eval do
      has_one :campaign, :as => :campaign_style, :dependent => :destroy
      delegate :account, :phone_numbers, :calls, :contact_forms, :submissions, :websites, :status, :name, :target_cities, :to => :campaign
      accepts_nested_attributes_for :campaign
    end
  end

end