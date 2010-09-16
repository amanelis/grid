class AddForwardingBccEmailToContactForm < ActiveRecord::Migration
  def self.up
    add_column :contact_forms, :forwarding_bcc_email, :string
  end

  def self.down
    remove_column :contact_forms, :forwarding_bcc_email
  end
end
