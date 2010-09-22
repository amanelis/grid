class AddReferenceFromAdwordsAdSummaryToAdwordsKeyword < ActiveRecord::Migration
  def self.up
    add_column :adwords_ad_summaries, :adwords_keyword_id, :integer, :null => false
  end

  def self.down
    remove_column :adwords_ad_summaries, :adwords_keyword_id
  end
end
