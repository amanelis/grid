class AddActiveFlagToContactForm < ActiveRecord::Migration
  def self.up
    add_column :contact_forms, :active, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :contact_forms, :active
  end
end
