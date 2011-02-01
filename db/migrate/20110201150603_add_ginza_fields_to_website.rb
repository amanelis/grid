class AddGinzaFieldsToWebsite < ActiveRecord::Migration
  def self.up
    add_column :websites, :ginza_global_id, :string
    add_column :websites, :ginza_meta_descript, :string
  end

  def self.down
    remove_column :websites, :ginza_global_id
    remove_column :websites, :ginza_meta_descript
  end
end
