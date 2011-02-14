class AddManipulatorToAccountUsers < ActiveRecord::Migration
  def self.up
    add_column :account_users, :manipulator, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :account_users, :manipulator
  end
end
