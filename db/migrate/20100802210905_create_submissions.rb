class CreateSubmissions < ActiveRecord::Migration
  def self.up
    create_table :submissions do |t|
      t.references :contact_form, :null => false
      t.string :from_email
      t.string :ip_address
      t.string :name
      t.string :home_address
      t.string :work_category
      t.string :work_description
      t.string :other_information
      t.string :custom1_value
      t.string :custom2_value
      t.string :custom3_value
      t.string :custom4_value
      t.date :date_requested
      t.string :time_requested
      t.string :phone_number
      t.timestamps
    end
  end

  def self.down
    drop_table :submissions
  end
end
