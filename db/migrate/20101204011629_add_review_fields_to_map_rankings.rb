class AddReviewFieldsToMapRankings < ActiveRecord::Migration
  def self.up
    add_column :map_rankings, :google_places_ranking, :float
    add_column :map_rankings, :google_insiderpages_review_count, :integer
    add_column :map_rankings, :google_customerlobby_review_count, :integer
    add_column :map_rankings, :google_citysearch_review_count, :integer
    add_column :map_rankings, :google_judysbook_review_count, :integer
    add_column :map_rankings, :google_yahoo_review_count, :integer
    add_column :map_rankings, :google_insiderpages_rating, :integer
    add_column :map_rankings, :google_customerlobby_rating, :integer
    add_column :map_rankings, :google_citysearch_rating, :integer
    add_column :map_rankings, :google_judysbook_rating, :integer
    add_column :map_rankings, :google_yahoo_rating, :integer
  end

  def self.down
    remove_column :map_rankings, :google_places_ranking
    remove_column :map_rankings, :google_insiderpages_review_count
    remove_column :map_rankings, :google_customerlobby_review_count
    remove_column :map_rankings, :google_citysearch_review_count
    remove_column :map_rankings, :google_judysbook_review_count
    remove_column :map_rankings, :google_yahoo_review_count
    remove_column :map_rankings, :google_insiderpages_rating
    remove_column :map_rankings, :google_customerlobby_rating
    remove_column :map_rankings, :google_citysearch_rating
    remove_column :map_rankings, :google_judysbook_rating
    remove_column :map_rankings, :google_yahoo_rating
  end
end
