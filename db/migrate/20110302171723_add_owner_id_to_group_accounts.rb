class AddOwnerIdToGroupAccounts < ActiveRecord::Migration
  def self.up
    add_column :group_accounts, :owner_id, :integer
  end

  def self.down
    remove_column :group_accounts, :owner_id
  end
end
