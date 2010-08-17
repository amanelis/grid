class AddOriginalTimeToWebsiteVisit < ActiveRecord::Migration
  def self.up
    change_table :website_visits do |t|
      t.datetime :time_of_visit
    end
  end

  def self.down
  end
end
