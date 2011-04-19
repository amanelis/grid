class AddCycleStartDayToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :cycle_start_day, :integer
  end

  def self.down
    remove_column :channels, :cycle_start_day
  end
end
