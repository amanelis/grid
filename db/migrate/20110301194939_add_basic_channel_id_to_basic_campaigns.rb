class AddBasicChannelIdToBasicCampaigns < ActiveRecord::Migration
  def self.up
    add_column :basic_campaigns, :basic_channel_id, :integer
  end

  def self.down
    remove_column :basic_campaigns, :basic_channel_id
  end
end
