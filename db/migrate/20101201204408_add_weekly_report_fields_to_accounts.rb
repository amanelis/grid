class AddWeeklyReportFieldsToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :receive_weekly_report, :boolean, :default => true, :null => false
    add_column :accounts, :last_weekly_report_sent, :datetime
  end

  def self.down
    remove_column :accounts, :receive_weekly_report
    remove_column :accounts, :last_weekly_report_sent
  end
end
