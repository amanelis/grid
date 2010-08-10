class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords
  has_many :inbound_links
  has_many :website_analyses, :class_name => "WebsiteAnalysis"
end
