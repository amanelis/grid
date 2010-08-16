class CreateSemCampaigns < ActiveRecord::Migration
  def self.up
    create_table :sem_campaigns do |t|
      t.float :monthly_budget
      t.float :rake
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
    drop_table :sem_campaigns
  end
end
