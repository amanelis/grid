class CreateAccountManagers < ActiveRecord::Migration
  def self.up
    create_table :account_managers do |t|
      t.references :group_account, :null => false
      t.string :name
      t.string :phone_number
      t.string :email
      t.timestamps
    end
  end

  def self.down
    drop_table :account_managers
  end
end
