class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string :account_type
      t.string :status
      t.string :name
      t.string :street
      t.string :city
      t.string :county
      t.string :state
      t.string :postal_code
      t.string :country
      t.string :phone
      t.string :other_phone
      t.string :fax
      t.string :metro_area
      t.string :website
      t.string :industry
      t.string :main_contact
      t.string :salesforce_id
      t.timestamps
    end
  end

  def self.down
    drop_table :accounts
  end
end
