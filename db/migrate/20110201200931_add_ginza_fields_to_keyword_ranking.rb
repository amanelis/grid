class AddGinzaFieldsToKeywordRanking < ActiveRecord::Migration
  def self.up
    add_column :keyword_rankings, :date_of_ranking, :date
    add_column :keyword_rankings, :ginza_conv_percent, :float
    add_column :keyword_rankings, :ginza_conversions, :integer
    add_column :keyword_rankings, :ginza_visits, :integer
    
    KeywordRanking.reset_column_information
    KeywordRanking.all.each { |ranking| ranking.update_attribute(:date_of_ranking, ranking.created_at.to_date) }
    end
    
  end

  def self.down
    remove_column :keyword_rankings, :date_of_ranking
    remove_column :keyword_rankings, :ginza_conv_percent
    remove_column :keyword_rankings, :ginza_conversions
    remove_column :keyword_rankings, :ginza_visits
  end
end
