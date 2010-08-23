class MapsCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_maps_campaigns
  has_many :yahoo_maps_campaigns
  has_many :bing_maps_campaigns
  has_many :map_keywords
end
