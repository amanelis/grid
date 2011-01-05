class CreateAccountUsers < ActiveRecord::Migration
  def self.up
    create_table :account_users do |t|
      t.references :account, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :account_users
  end
end
