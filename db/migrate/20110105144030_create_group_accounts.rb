class CreateGroupAccounts < ActiveRecord::Migration
  def self.up
    create_table :group_accounts do |t|
      t.string :status
      t.string :name
      t.string :salesforce_id
      t.timestamps
    end
  end

  def self.down
    drop_table :group_accounts
  end
end
