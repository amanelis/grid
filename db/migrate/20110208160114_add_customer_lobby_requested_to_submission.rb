class AddCustomerLobbyRequestedToSubmission < ActiveRecord::Migration
  def self.up
    add_column :submissions, :customer_lobby_requested, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :submissions, :customer_lobby_requested
  end
end
