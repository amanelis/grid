class AddAccountManagerIdToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :account_manager_id, :integer
  end

  def self.down
    remove_column :accounts, :account_manager_id
  end
end
