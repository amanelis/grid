class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords
  has_many :inbound_links
end
