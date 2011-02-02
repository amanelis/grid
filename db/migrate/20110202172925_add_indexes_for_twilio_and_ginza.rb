class AddIndexesForTwilioAndGinza < ActiveRecord::Migration
  def self.up
    add_index 'websites', 'ginza_global_id'
    add_index 'phone_numbers', 'twilio_id'
    add_index 'accounts', 'twilio_id'
    add_index 'keywords', 'ginza_keyword_id'
  end

  def self.down
    remove_index 'websites', 'ginza_global_id'
    remove_index 'phone_numbers', 'twilio_id'
    remove_index 'accounts', 'twilio_id'
    remove_index 'keywords', 'ginza_keyword_id'
  end
end
