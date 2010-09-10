class CreateOtherCampaigns < ActiveRecord::Migration
  def self.up
    create_table :other_campaigns do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :other_campaigns
  end
end
