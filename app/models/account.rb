class Account < ActiveRecord::Base
  has_many :campaigns

  
  def self.pull_all_data_migrations
    puts "Pulling Salesforce Accounts..."
    Account.pull_salesforce_accounts
    puts "Pulling Salesforce Campaigns..."
    Campaign.pull_salesforce_campaigns
    puts "Pulling Salesforce Phone Numbers..."
    PhoneNumber.get_salesforce_numbers
    puts "Updating Calls..."
    Call.update_calls
    puts "Adding Websites..."
    Website.add_websites
    puts "Updating Website Visits..."
    WebsiteVisit.data_pull_websites_visits
    puts "Pulling Salesforce Keywords..."
    Keyword.update_keywords_from_salesforce
    puts "Updating Keyword Rankings..."
    Keyword.update_keyword_rankings
    puts "Done."
  end

  def self.pull_salesforce_accounts
    sf_accounts = Salesforce::Account.find(:all, :conditions => ['account_status__c = ? OR account_status__c = ?', "Active", "Paused"])

    sf_accounts.each do |sf_account|
      Account.find_or_create_by_salesforce_id(:salesforce_id => sf_account.id,
                                              :account_type => sf_account.account_type__c,
                                              :status => sf_account.account_status__c,
                                              :name => sf_account.name,
                                              :street => sf_account.billing_street,
                                              :city => sf_account.billing_city,
                                              :county => sf_account.county__c,
                                              :state => sf_account.billing_state,
                                              :postal_code => sf_account.billing_postal_code,
                                              :country => sf_account.billing_country,
                                              :phone => sf_account.phone,
                                              :other_phone => sf_account.other_phone_number__c,
                                              :fax => sf_account.fax,
                                              :metro_area => sf_account.metro_area__c,
                                              :website => sf_account.website,
                                              :industry => sf_account.industry,
                                              :main_contact => sf_account.main_contact__c)
    end
  end


end
