class AdwordsCampaign < ActiveRecord::Base
  belongs_to :google_sem_campaign
  has_many :adwords_campaign_summaries
  has_many :adwords_ad_groups
end
