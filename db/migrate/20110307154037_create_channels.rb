class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.references :account, :null => false
      t.string :name
      t.string :channel_type
      t.timestamps
    end
  end

  def self.down
    drop_table :channels
  end
end
