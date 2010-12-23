class AddAccountManagerToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :account_manager, :string
  end

  def self.down
    remove_column :accounts, :account_manager
  end
end
