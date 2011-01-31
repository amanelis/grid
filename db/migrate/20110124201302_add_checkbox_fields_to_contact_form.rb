class AddCheckboxFieldsToContactForm < ActiveRecord::Migration
  def self.up
    add_column :contact_forms, :return_url, :string, :null => false
    add_column :contact_forms, :need_name, :boolean, :default => true, :null => false
    add_column :contact_forms, :need_address, :boolean, :default => true, :null => false
    add_column :contact_forms, :need_phone, :boolean, :default => true, :null => false
    add_column :contact_forms, :need_email, :boolean, :default => true, :null => false
    add_column :contact_forms, :work_category, :boolean, :default => true, :null => false
    add_column :contact_forms, :work_description, :boolean, :default => true, :null => false
    add_column :contact_forms, :date_requested, :boolean, :default => true, :null => false
    add_column :contact_forms, :time_requested, :boolean, :default => true, :null => false
    add_column :contact_forms, :other_information, :boolean, :default => true, :null => false
    add_column :contact_forms, :html_block, :text
    
  end

  def self.down
    remove_column :contact_forms, :return_url
    remove_column :contact_forms, :need_name
    remove_column :contact_forms, :need_address
    remove_column :contact_forms, :need_phone
    remove_column :contact_forms, :need_email
    remove_column :contact_forms, :work_category
    remove_column :contact_forms, :work_description
    remove_column :contact_forms, :date_requested
    remove_column :contact_forms, :time_requested
    remove_column :contact_forms, :other_information
    remove_column :contact_forms, :html_block
  end
end
