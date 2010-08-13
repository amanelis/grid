class CreateSemCampaignReportStatuses < ActiveRecord::Migration
  def self.up
    create_table :sem_campaign_report_statuses do |t|
      t.references :sem_campaign, :null => false
      t.string :provider
      t.string :report_type
      t.string :pulled_on
      t.string :result
      t.integer :job_id
      t.timestamps
    end
  end

  def self.down
    drop_table :sem_campaign_report_statuses
  end
end
