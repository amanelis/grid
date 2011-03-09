class AddIndexesForChannelsAndStuff < ActiveRecord::Migration
  def self.up
    add_index 'campaigns', 'channel_id'
    add_index 'accounts', 'customer_lobby_id'
    add_index 'channels', 'account_id'
    add_index 'group_accounts', 'owner_id'
  end

  def self.down
    remove_index 'campaigns', 'channel_id'
    remove_index 'accounts', 'customer_lobby_id'
    remove_index 'channels', 'account_id'
    remove_index 'group_accounts', 'owner_id'
  end
end
