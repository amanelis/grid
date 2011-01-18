class AddTwilioFieldsToCall < ActiveRecord::Migration
  def self.up
    add_column :calls, :caller_city, :string
    add_column :calls, :caller_state, :string
    add_column :calls, :caller_zipcode, :string
    add_column :calls, :caller_country, :string
    add_column :calls, :cost, :string
  end

  def self.down
    remove_column :calls, :caller_city
    remove_column :calls, :caller_state
    remove_column :calls, :caller_zipcode
    remove_column :calls, :caller_country
    remove_column :calls, :cost
  end
end
