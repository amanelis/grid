class AddBingDataToMapRankings < ActiveRecord::Migration
  def self.up
    add_column :map_rankings, :bing_review_count, :integer
  end

  def self.down
    remove_column :map_rankings, :bing_review_count
  end
end
