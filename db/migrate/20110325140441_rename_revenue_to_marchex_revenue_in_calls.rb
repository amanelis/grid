class RenameRevenueToMarchexRevenueInCalls < ActiveRecord::Migration
  def self.up
    rename_column :calls, :revenue, :marchex_revenue
  end

  def self.down
    rename_column :calls, :marchex_revenue, :revenue
  end
end
