class CreateCalls < ActiveRecord::Migration
  def self.up
    create_table :calls do |t|
      t.references :phone_number, :null => false
      t.string :call_id
      t.string :assigned_to
      t.datetime :call_end
      t.datetime :call_start
      t.string :call_status
      t.string :caller_name
      t.string :caller_number
      t.string :disposition
      t.string :forwardno
      t.string :inbound_ext
      t.string :inboundno
      t.string :rating
      t.string :revenue
      t.boolean :recorded
      t.timestamps
    end
  end

  def self.down
    drop_table :calls
  end
end
