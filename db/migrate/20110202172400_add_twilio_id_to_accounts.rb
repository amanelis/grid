class AddTwilioIdToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :twilio_id, :string
  end

  def self.down
    remove_column :accounts, :twilio_id
  end
end
