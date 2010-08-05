class CreateWebsites < ActiveRecord::Migration
  def self.up
    create_table :websites do |t|
      t.string :domain
      t.string :nickname
      t.string :mirrors
      t.string :timezone
      t.string :dst
      t.string :site_id
      t.string :sitekey
      t.string :database_server
      t.string :admin_sitekey
      t.integer :url_id
      t.boolean :is_active
      t.timestamps
    end
  end

  def self.down
    drop_table :websites
  end
end
