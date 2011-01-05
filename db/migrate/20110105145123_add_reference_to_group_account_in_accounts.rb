class AddReferenceToGroupAccountInAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :group_account_id, :integer, :null => false
  end

  def self.down
    remove_column :accounts, :group_account_id
  end
end
