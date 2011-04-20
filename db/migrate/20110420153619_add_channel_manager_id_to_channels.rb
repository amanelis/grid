class AddChannelManagerIdToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :channel_manager_id, :integer
  end

  def self.down
    remove_column :channels, :channel_manager_id
  end
end
