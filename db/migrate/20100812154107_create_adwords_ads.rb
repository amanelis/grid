class CreateAdwordsAds < ActiveRecord::Migration
  def self.up
    create_table :adwords_ads do |t|
      t.references :adwords_ad_group, :null => false
      t.string :reference_id
      t.string :status
      t.string :creative_type
      t.string :dest_url
      t.string :headline
      t.string :desc1
      t.string :desc2
      t.string :dest_url
      t.string :img_name
      t.string :hosting_key
      t.string :preview
      t.string :vis_url
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_ads
  end
end
