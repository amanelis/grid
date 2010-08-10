class CreateKeywordRankings < ActiveRecord::Migration
  def self.up
    create_table :keyword_rankings do |t|
      t.references :keyword, :null => false
      t.integer :bing
      t.integer :yahoo
      t.integer :google
      t.float :relevancy
      t.float :cpc
      t.timestamps
    end
  end

  def self.down
    drop_table :keyword_rankings
  end
end
