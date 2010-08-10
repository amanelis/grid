class CreateWebsiteAnalyses < ActiveRecord::Migration
  def self.up
    create_table :website_analyses do |t|
      t.references :seo_campaign, :null => false
      t.integer  "pear_score"
      t.integer  "google_pagerank"
      t.integer  "alexa_rank"
      t.integer  "page_specific_inbound_link_count"
      t.integer  "sitewide_inbound_link_count"
      t.timestamps
    end
  end

  def self.down
    drop_table :website_analyses
  end
end
