class AddSalesforceIdToCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :salesforce_id, :string
  end

  def self.down
    remove_column :campaigns, :salesforce_id
  end
end
