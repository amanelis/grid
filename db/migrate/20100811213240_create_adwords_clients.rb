class CreateAdwordsClients < ActiveRecord::Migration
  def self.up
    create_table :adwords_clients do |t|
      t.references :account
      t.string :name
      t.string :reference_id
      t.string :address
      t.string :business_name
      t.string :timezone
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_clients
  end
end
