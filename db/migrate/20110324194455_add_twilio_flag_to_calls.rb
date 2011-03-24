class AddTwilioFlagToCalls < ActiveRecord::Migration
  def self.up
    add_column :calls, :twilio, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :calls, :twilio
  end
end
