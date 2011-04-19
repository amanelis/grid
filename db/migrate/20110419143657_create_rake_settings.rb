class CreateRakeSettings < ActiveRecord::Migration
  def self.up
    create_table :rake_settings do |t|
      t.references :channel, :null => false
      t.integer :percentage
      t.date :start_date
      t.timestamps
    end
  end

  def self.down
    drop_table :rake_settings
  end
end
