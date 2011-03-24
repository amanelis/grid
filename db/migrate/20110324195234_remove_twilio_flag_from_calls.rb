class RemoveTwilioFlagFromCalls < ActiveRecord::Migration
  def self.up
    remove_column :calls, :twilio
  end

  def self.down
    add_column :calls, :twilio, :boolean, :default => false, :null => false
  end
end
