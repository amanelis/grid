class CreateKeywords < ActiveRecord::Migration
  def self.up
    create_table :keywords do |t|
      t.references :seo_campaign, :null => false
      t.string :descriptor
      t.boolean :google_first_page
      t.boolean :yahoo_first_page
      t.boolean :bing_first_page
      t.timestamps
    end
  end

  def self.down
    drop_table :keywords
  end
end
