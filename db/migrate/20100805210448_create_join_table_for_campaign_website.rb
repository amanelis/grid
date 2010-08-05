class CreateJoinTableForCampaignWebsite < ActiveRecord::Migration
  def self.up
    create_table :campaigns_websites, :id => false do |t|
      t.integer :campaign_id, :null => false
      t.integer :website_id, :null => false
    end
  end

  def self.down
    drop_table :campaigns_websites
  end
end
