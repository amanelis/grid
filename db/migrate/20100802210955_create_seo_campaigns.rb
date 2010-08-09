class CreateSeoCampaigns < ActiveRecord::Migration
  def self.up
    create_table :seo_campaigns do |t|
      t.string :cities
      t.float :budget
      t.string :dns_host
      t.string :dns_login
      t.string :dns_password
      t.string :hosting_site
      t.string :hosting_username
      t.string :hosting_password
      t.timestamps
    end
  end

  def self.down
    drop_table :seo_campaigns
  end
end
