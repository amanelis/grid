class CreateBingMapsCampaigns < ActiveRecord::Migration
  def self.up
    create_table :bing_maps_campaigns do |t|
      t.references :maps_campaign, :null => false
      t.string :login
      t.string :password
      t.string :maps_url
      t.string :reference_id
      t.timestamps
    end
  end

  def self.down
    drop_table :bing_maps_campaigns
  end
end
