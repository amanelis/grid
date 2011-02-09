class AddManipulatorToGroupUsers < ActiveRecord::Migration
  def self.up
    add_column :group_users, :manipulator, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :group_users, :manipulator
  end
end
