class CreateInboundLinks < ActiveRecord::Migration
  def self.up
    create_table :inbound_links do |t|
      t.references :seo_campaign, :null => false
      t.string :link_url
      t.date :last_date_found
      t.timestamps
    end
  end

  def self.down
    drop_table :inbound_links
  end
end
