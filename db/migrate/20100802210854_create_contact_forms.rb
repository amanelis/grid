class CreateContactForms < ActiveRecord::Migration
  def self.up
    create_table :contact_forms do |t|
      t.references :campaign, :null => false
      t.string :forwarding_email
      t.string :custom1_text
      t.string :custom2_text
      t.string :custom3_text
      t.string :custom4_text
      t.timestamps
    end
  end

  def self.down
    drop_table :contact_forms
  end
end
