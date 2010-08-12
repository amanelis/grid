class CreateAdwordsKeywords < ActiveRecord::Migration
  def self.up
    create_table :adwords_keywords do |t|
      t.string :descriptor
      t.string :reference_id
      t.string :status
      t.string :dest_url
      t.string :keyword_type
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_keywords
  end
end
