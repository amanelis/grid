class CreateSemCampaigns < ActiveRecord::Migration
  def self.up
    create_table :sem_campaigns do |t|
      t.float :monthly_budget
      t.float :rake
      t.timestamps
    end
  end

  def self.down
    drop_table :sem_campaigns
  end
end
