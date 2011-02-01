class AddGinzaFieldsToKeyword < ActiveRecord::Migration
  def self.up
    add_column :keywords, :last_ranking_update, :date
    add_column :keywords, :ginza_keyword_id, :integer
  end

  def self.down
    remove_column :keywords, :last_ranking_update
    remove_column :keywords, :ginza_keyword_id
  end
end
