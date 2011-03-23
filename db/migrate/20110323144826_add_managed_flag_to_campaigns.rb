class AddManagedFlagToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :managed, :boolean, :default => true, :null => false
    Campaign.reset_column_information
    Campaign.all.each { |campaign| campaign.update_attribute(:managed, campaign.managed_flavor?) }
  end

  def self.down
    remove_column :campaigns, :managed
  end
end
