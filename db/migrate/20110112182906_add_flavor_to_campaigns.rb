class AddFlavorToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :flavor, :string
  end

  def self.down
    remove_column :campaigns, :flavor
  end
end
