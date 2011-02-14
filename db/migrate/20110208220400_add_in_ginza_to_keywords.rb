class AddInGinzaToKeywords < ActiveRecord::Migration
  def self.up
    add_column :keywords, :in_ginza, :boolean, :default => false, :null => false
    
    Keyword.reset_column_information
    Keyword.all.each { |keyword| keyword.update_attribute(:in_ginza, false) }
  end

  def self.down
    remove_column :keywords, :in_ginza
  end
end
