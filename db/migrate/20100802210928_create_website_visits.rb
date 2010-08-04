class CreateWebsiteVisits < ActiveRecord::Migration
  def self.up
    create_table :website_visits do |t|
      t.references :website, :null => false
      t.string :actions
      t.string :clicky_url
      t.string :latitude
      t.string :longitude
      t.string :language
      t.string :screen_resolution
      t.string :time
      t.string :time_pretty
      t.string :time_total
      t.string :ip_address
      t.string :session_id
      t.string :geolocation
      t.string :javascript
      t.string :web_browser
      t.string :operating_system
      t.string :referrer_url
      t.string :referrer_domain
      t.string :referrer_search
      t.string :hostname
      t.string :organization
      t.string :campaign
      t.string :goals
      t.string :custom
      t.timestamps
    end
  end

  def self.down
    drop_table :website_visits
  end
end
