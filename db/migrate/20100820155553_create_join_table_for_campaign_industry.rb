class CreateJoinTableForCampaignIndustry < ActiveRecord::Migration
  def self.up
    create_table :campaigns_industries, :id => false do |t|
      t.integer :campaign_id, :null => false
      t.integer :industry_id, :null => false
    end
  end

  def self.down
    drop_table :campaigns_industries
  end
end
