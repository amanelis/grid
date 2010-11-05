class AddResellerIdToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :reseller_id, :integer
  end

  def self.down
    remove_column :accounts, :reseller_id
  end
end
