class CreateSubmissions < ActiveRecord::Migration
  def self.up
    create_table :submissions do |t|
      t.references :contact_form, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :submissions
  end
end
