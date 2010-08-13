class SemCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_sem_campaigns
  has_many :sem_campaign_report_statuses
end
