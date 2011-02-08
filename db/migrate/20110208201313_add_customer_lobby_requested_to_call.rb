class AddCustomerLobbyRequestedToCall < ActiveRecord::Migration
  def self.up
    add_column :calls, :customer_lobby_requested, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :calls, :customer_lobby_requested
  end
end
