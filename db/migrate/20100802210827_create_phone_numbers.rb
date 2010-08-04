class CreatePhoneNumbers < ActiveRecord::Migration
  def self.up
    create_table :phone_numbers do |t|
      t.references :campaign, :null => false
      t.string :name
      t.string :inboundno
      t.string :cmpid
      t.string :descript
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_numbers
  end
end
