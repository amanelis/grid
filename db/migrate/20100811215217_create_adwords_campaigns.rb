class CreateAdwordsCampaigns < ActiveRecord::Migration
  def self.up
    create_table :adwords_campaigns do |t|
      t.references :google_sem_campaign, :null => false
      t.string :name
      t.string :reference_id
      t.string :status
      t.integer :phone
      t.string :campaign_type
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_campaigns
  end
end
