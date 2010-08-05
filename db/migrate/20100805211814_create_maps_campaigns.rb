class CreateMapsCampaigns < ActiveRecord::Migration
  def self.up
    create_table :maps_campaigns do |t|
      t.string :keywords
      t.string :company_name
      t.timestamps
    end
  end

  def self.down
    drop_table :maps_campaigns
  end
end
