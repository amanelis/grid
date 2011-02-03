class AddLastKeywordUpdateFieldToWebsite < ActiveRecord::Migration
  def self.up
    add_column :websites, :last_keyword_update, :date
  end

  def self.down
    remove_column :websites, :last_keyword_update
  end
end
