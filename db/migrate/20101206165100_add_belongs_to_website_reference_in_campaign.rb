class AddBelongsToWebsiteReferenceInCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :website_id, :integer
    add_index :campaigns, :website_id
    drop_table :campaigns_websites
  end

  def self.down
    remove_index :campaigns, :website_id
    remove_column :campaigns, :website_id
    create_table :campaigns_websites, :id => false do |t|
      t.integer :campaign_id, :null => false
      t.integer :website_id, :null => false
    end
  end
end
