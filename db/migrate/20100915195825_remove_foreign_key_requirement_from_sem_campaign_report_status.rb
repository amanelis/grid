class RemoveForeignKeyRequirementFromSemCampaignReportStatus < ActiveRecord::Migration
  def self.up
    change_column :sem_campaign_report_statuses, :sem_campaign_id, :integer, :null => true
  end

  def self.down
    change_column :sem_campaign_report_statuses, :sem_campaign_id, :integer, :null => false
  end
end
