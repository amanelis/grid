class CreateIndustryKeywords < ActiveRecord::Migration
  def self.up
    create_table :industry_keywords do |t|
      t.references :industry, :null => false
      t.string :descriptor
      t.timestamps
    end
  end

  def self.down
    drop_table :industry_keywords
  end
end
