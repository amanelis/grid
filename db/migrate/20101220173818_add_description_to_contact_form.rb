class AddDescriptionToContactForm < ActiveRecord::Migration
  def self.up
    add_column :contact_forms, :description, :string
  end

  def self.down
    remove_column :contact_forms, :description
  end
end
