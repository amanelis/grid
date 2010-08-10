class MapKeyword < ActiveRecord::Base
  belongs_to :maps_campaign
  has_many :map_rankings
end
