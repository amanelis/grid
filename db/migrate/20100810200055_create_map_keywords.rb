class CreateMapKeywords < ActiveRecord::Migration
  def self.up
    create_table :map_keywords do |t|
      t.references :maps_campaign, :null => false
      t.string :descriptor
      t.date :ranking_updated_on
      t.timestamps
    end
  end

  def self.down
    drop_table :map_keywords
  end
end
