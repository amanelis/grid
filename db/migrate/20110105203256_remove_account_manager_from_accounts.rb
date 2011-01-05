class RemoveAccountManagerFromAccounts < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :account_manager
  end

  def self.down
    add_column :accounts, :account_manager, :string
  end
end
