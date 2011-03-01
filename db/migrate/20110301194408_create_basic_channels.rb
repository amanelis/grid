class CreateBasicChannels < ActiveRecord::Migration
  def self.up
    create_table :basic_channels do |t|
      t.references :account, :null => false
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :basic_channels
  end
end
