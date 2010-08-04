class CreateGoogleSemCampaigns < ActiveRecord::Migration
  def self.up
    create_table :google_sem_campaigns do |t|
      t.references :sem_campaign, :null => false
      t.string :google_campaign_id
      t.string :developer_token
      t.string :application_token
      t.string :user_agent
      t.string :password
      t.string :email
      t.string :client_email
      t.string :environment
      t.timestamps
    end
  end

  def self.down
    drop_table :google_sem_campaigns
  end
end
