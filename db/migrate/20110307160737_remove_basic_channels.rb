class RemoveBasicChannels < ActiveRecord::Migration
  def self.up
    drop_table :basic_channels
  end

  def self.down
    create_table :basic_channels do |t|
      t.references :account, :null => false
      t.string :name
      t.timestamps
    end
  end
end
