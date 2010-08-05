namespace :salesforce do
  desc "Creates migrations for Salesforce Accounts, Leads, Opportunities, Client Campaigns and Contacts."
  task :create_migrations => :environment do
    include SalesforceHelpers
    ActiveRecord::Schema.define() do
      #puts "Create local schema for Leads"
      #eval(dumpclass(Salesforce::Lead))
      #puts "Create local schema for Contacts"
      #eval(dumpclass(Salesforce::Contact))
      #puts "Create local schema for Accounts"
      #eval(dumpclass(Salesforce::Account))
      #puts "Create local schema for Opportunities"
      #eval(dumpclass(Salesforce::Opportunity))
      #puts "Create local schema for Client Campaigns"
      #eval(dumpclass(Salesforce::Clientcampaign))
    end
  end  

  #desc "Prefill the data for Salesforce Accounts, Leads, Opportunities, Client Campaigns and Contacts. This will delete all existing objects, recreate the DB schema and then repopulate the data."
  #task :hard_update => :environment do
    #include SalesforceHelpers
    #puts "Hard updating the Leads"
    #hard_update_class(Salesforce::Lead, Lead)
    #puts "Hard updating the Contact"
    #hard_update_class(Salesforce::Contact, Contact)
    #puts "Hard updating the Account"
    #hard_update_class(Salesforce::Account, Account)
    #puts "Hard updating the Opportunities"
   # hard_update_class(Salesforce::Opportunity, Opportunity)
    #puts "Hard updating the Client Campaigns"
    #hard_update_class(Salesforce::Clientcampaign, Clientcampaign)
  #end
  
  desc "Update the data for Salesforce Accounts, Leads, Opportunities, Client Campaigns and Contacts."
  task :soft_update => :environment do
    include SalesforceHelpers
    #puts "Soft updating the Leads"
    #update_class(Salesforce::Lead, Lead)
    #puts "Soft updating the Contact"
    #update_class(Salesforce::Contact, Contact)
    puts "Soft updating the Account"
    update_class(Salesforce::Account, Account)
    #puts "Soft updating the Opportunities"
    #update_class(Salesforce::Opportunity, Opportunity)
    #puts "Soft updating the Client Campaign"
    #update_class(Salesforce::Clientcampaign, Clientcampaign)
  end
end