class MapsCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_maps_campaigns
  has_many :yahoo_maps_campaigns
  has_many :bing_maps_campaigns
  has_many :map_keywords

  
  # INSTANCE BEHAVIOR

  def combined_timeline_data
    Utilities.merge_timeline_data(self.campaign.number_of_map_visits_by_date)
  end

end
