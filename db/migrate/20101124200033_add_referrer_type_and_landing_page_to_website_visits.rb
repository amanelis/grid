class AddReferrerTypeAndLandingPageToWebsiteVisits < ActiveRecord::Migration
  def self.up
    add_column :website_visits, :landing_page, :string
    add_column :website_visits, :referrer_type, :string
  end

  def self.down
    remove_column :website_visits, :landing_page
    remove_column :website_visits, :referrer_type
  end
end
