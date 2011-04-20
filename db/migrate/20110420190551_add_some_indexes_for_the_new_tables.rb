class AddSomeIndexesForTheNewTables < ActiveRecord::Migration
  def self.up
    add_index 'rake_settings', 'channel_id'
    add_index 'budget_infusions', 'channel_id'
    add_index 'channels', 'channel_manager_id'
    add_index 'budget_settings', 'channel_id'
  end

  def self.down
    remove_index 'rake_settings', 'channel_id'
    remove_index 'budget_infusions', 'channel_id'
    remove_index 'channels', 'channel_manager_id'
    remove_index 'budget_settings', 'channel_id'
  end
end
