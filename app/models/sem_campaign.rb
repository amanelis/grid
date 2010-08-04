class SemCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_sem_campaigns
end
