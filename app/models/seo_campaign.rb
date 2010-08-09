class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords
end
