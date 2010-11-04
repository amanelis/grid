class AddReportingEmailsToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :reporting_emails, :string
  end

  def self.down
    remove_column :accounts, :reporting_emails
  end
end
