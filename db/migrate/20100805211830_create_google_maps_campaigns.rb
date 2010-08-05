class CreateGoogleMapsCampaigns < ActiveRecord::Migration
  def self.up
    create_table :google_maps_campaigns do |t|
      t.references :maps_campaign, :null => false
      t.string :login
      t.string :password
      t.timestamps
    end
  end

  def self.down
    drop_table :google_maps_campaigns
  end
end
