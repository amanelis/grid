class AddRevenueToActivities < ActiveRecord::Migration
  def self.up
    add_column :activities, :revenue, :float
  end

  def self.down
    remove_column :activities, :revenue
  end
end
