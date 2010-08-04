class AddSalesforceIdToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :salesforce_id, :string
  end

  def self.down
    remove_column :accounts, :salesforce_id
  end
end
