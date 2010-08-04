class CreateCampaigns < ActiveRecord::Migration
  def self.up
    create_table :campaigns do |t|
      t.references :account, :null => false
      t.references :campaign_style, :polymorphic => true, :null => false
      t.string :status
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :campaigns
  end
end
