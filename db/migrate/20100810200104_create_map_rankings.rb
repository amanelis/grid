class CreateMapRankings < ActiveRecord::Migration
  def self.up
    create_table :map_rankings do |t|
      t.references :map_keyword, :null => false
      t.date :ranking_date
      t.integer :google_rank
      t.integer :yahoo_rank
      t.integer :bing_rank
      t.integer :google_coupon_count
      t.integer :google_review_count
      t.integer :google_citation_count
      t.integer :google_user_content_count
      t.timestamps
    end
  end

  def self.down
    drop_table :map_rankings
  end
end
