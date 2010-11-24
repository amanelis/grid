class AddVisitorIdToWebsiteVisits < ActiveRecord::Migration
  def self.up
    add_column :website_visits, :visitor_id, :string
  end

  def self.down
    remove_column :website_visits, :visitor_id
  end
end
