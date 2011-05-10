class RemoveResellerIdFromAccounts < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :reseller_id
  end

  def self.down
    add_column :accounts, :reseller_id, :integer
  end
end
