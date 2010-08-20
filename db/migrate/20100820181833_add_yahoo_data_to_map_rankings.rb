class AddYahooDataToMapRankings < ActiveRecord::Migration
  def self.up
    add_column :map_rankings, :yahoo_review_count, :integer
    add_column :map_rankings, :yahoo_review_rating, :float
    add_column :map_rankings, :yahoo_last_review_date, :date
  end

  def self.down
    remove_column :map_rankings, :yahoo_review_count
    remove_column :map_rankings, :yahoo_review_rating
    remove_column :map_rankings, :yahoo_last_review_date
  end
end
