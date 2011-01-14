class AddActiveFieldToPhoneNumber < ActiveRecord::Migration
  def self.up
    add_column :phone_numbers, :active, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :phone_numbers, :active
  end
end
