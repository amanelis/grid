class AddTimeZoneToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :time_zone, :string
    Account.reset_column_information
    Account.all.each do |account|
      account.time_zone = "Central Time (US & Canada)"
      account.save
    end
  end

  def self.down
    remove_column :accounts, :time_zone
  end
end
