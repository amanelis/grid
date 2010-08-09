class Account < ActiveRecord::Base
  has_many :campaigns

  def self.pull_all_data_migrations()
    Account.pull_salesforce_accounts
    Campaign.pull_salesforce_campaigns
    PhoneNumber.get_salesforce_numbers
    Call.update_calls
    Website.add_websites
    WebsiteVisit.data_pull_websites_visits
    Keyword.update_keywords_from_salesforce
    
  end

  def self.pull_salesforce_accounts()
    accounts = Salesforce::Account.find(:all, :conditions => ['account_status__c = ? OR account_status__c = ?', "Active", "Paused"])

    accounts.each do |account|
      Account.find_or_create_by_salesforce_id(:salesforce_id => account.id,
                                              :account_type => account.account_type__c,
                                              :status => account.account_status__c,
                                              :name => account.name,
                                              :street => account.billing_street,
                                              :city => account.billing_city,
                                              :county => account.county__c,
                                              :state => account.billing_state,
                                              :postal_code => account.billing_postal_code,
                                              :country => account.billing_country,
                                              :phone => account.phone,
                                              :other_phone => account.other_phone_number__c,
                                              :fax => account.fax,
                                              :metro_area => account.metro_area__c,
                                              :website => account.website,
                                              :industry => account.industry,
                                              :main_contact => account.main_contact__c)
    end
  end


end
