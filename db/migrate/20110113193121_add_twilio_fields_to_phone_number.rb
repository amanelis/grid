class AddTwilioFieldsToPhoneNumber < ActiveRecord::Migration
  def self.up
    add_column :phone_numbers, :forward_to, :string
    add_column :phone_numbers, :twilio_version, :string
    add_column :phone_numbers, :twilio_id, :string
    add_column :phone_numbers, :id_callers, :boolean
    add_column :phone_numbers, :transcribe_calls, :boolean
    add_column :phone_numbers, :text_calls, :boolean
    add_column :phone_numbers, :record_calls, :boolean
  end

  def self.down
    remove_column :phone_numbers, :forward_to
    remove_column :phone_numbers, :twilio_version
    remove_column :phone_numbers, :twilio_id
    remove_column :phone_numbers, :id_callers
    remove_column :phone_numbers, :transcribe_calls
    remove_column :phone_numbers, :text_calls
  end
end
