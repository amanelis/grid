class RemoveBasicChannelIdFromBasicCampaigns < ActiveRecord::Migration
  def self.up
    remove_column :basic_campaigns, :basic_channel_id
  end

  def self.down
    add_column :basic_campaigns, :basic_channel_id, :integer
  end
end
