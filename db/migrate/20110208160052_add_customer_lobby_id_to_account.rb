class AddCustomerLobbyIdToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :customer_lobby_id, :string
  end

  def self.down
    remove_column :accounts, :customer_lobby_id
  end
end
