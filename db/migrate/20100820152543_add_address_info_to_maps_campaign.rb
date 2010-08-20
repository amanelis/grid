class AddAddressInfoToMapsCampaign < ActiveRecord::Migration
  def self.up
    add_column :maps_campaigns, :street, :string
    add_column :maps_campaigns, :city, :string
    add_column :maps_campaigns, :county, :string
    add_column :maps_campaigns, :state, :string
    add_column :maps_campaigns, :postal_code, :string
    add_column :maps_campaigns, :country, :string
  end

  def self.down
    remove_column :maps_campaigns, :street
    remove_column :maps_campaigns, :city
    remove_column :maps_campaigns, :county
    remove_column :maps_campaigns, :state
    remove_column :maps_campaigns, :postal_code
    remove_column :maps_campaigns, :country
  end
end
