class AddTargetCitiesToCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :target_cities, :string
  end

  def self.down
    remove_column :campaigns, :target_cities
  end
end
