class AddWeeklyReportMtdToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :weekly_report_mtd, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :accounts, :weekly_report_mtd
  end
end
