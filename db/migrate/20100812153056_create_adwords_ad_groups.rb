class CreateAdwordsAdGroups < ActiveRecord::Migration
  def self.up
    create_table :adwords_ad_groups do |t|
      t.references :adwords_campaign, :null => false
      t.string :reference_id
      t.string :status
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_ad_groups
  end
end
