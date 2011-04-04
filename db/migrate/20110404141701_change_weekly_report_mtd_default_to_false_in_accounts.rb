class ChangeWeeklyReportMtdDefaultToFalseInAccounts < ActiveRecord::Migration
  def self.up
    change_column :accounts, :weekly_report_mtd, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :accounts, :weekly_report_mtd, :boolean, :default => true, :null => false
  end
end
