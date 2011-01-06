class GroupAccount < ActiveRecord::Base
  has_many :accounts

  validates_uniqueness_of :name, :case_sensitive => false
  
  
  # TESTING METHODS
  
  def self.print_account_structure
    GroupAccount.all.each do |gaccount|
      puts 'Group Account:' + gaccount.name
      accounts = gaccount.accounts
      accounts.each do |account|
        puts '------' + account.name
      end
    end
  end
  
  # CLASS BEHAVIOR
  
  def self.pull_all_data_migrations
    puts "Pulling Salesforce Accounts..."
    GroupAccount.pull_salesforce_accounts
    puts "Pulling Salesforce Campaigns..."
    Campaign.pull_salesforce_campaigns
    puts "Pulling Marchex Phone Numbers..."
    PhoneNumber.get_marchex_numbers
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
    puts "Updating Inbound Links"
    SeoCampaign.update_inbound_links
    puts "Cleaning Inbound Links"
    SeoCampaign.clean_up_inbound_links
    puts "Updating Website Analyses"
    SeoCampaign.update_website_analyses
    puts "Updating Map Keywords"
    MapKeyword.update_keywords_from_salesforce
    puts "Updating Map Keyword Rankings"
    MapKeyword.update_map_rankings
    puts 'Updating Adwords Campaign Level Reports'
    SemCampaign.update_sem_campaign_reports_by_campaign
    puts 'Updating Adwords Ad Level Reports'
    SemCampaign.update_sem_campaign_reports_by_ad
    puts 'Updating Campaign.target_cities'
    Campaign.fix_target_cities
    puts "Done."
  end
  
  
  def self.pull_salesforce_accounts
    job_status = JobStatus.create(:name => "GroupAccount.pull_salesforce_accounts")
    begin
      cityvoice_account = Account.find_by_name("CityVoice")
      cityvoice_group_account = GroupAccount.find_by_name("CityVoice")
      
      if cityvoice_group_account.blank?
        cityvoice_account = Salesforce::Account.find(:all, :conditions => ['name = ?', 'CityVoice']).first
        cityvoice_group_account = GroupAccount.new
        cityvoice_group_account.salesforce_id = cityvoice_account.id
        cityvoice_group_account.name = cityvoice_account.name
        cityvoice_group_account.status = cityvoice_account.account_status__c
        cityvoice_group_account.save
      end
        
      sf_accounts = Salesforce::Account.find(:all, :conditions => ['account_status__c != ?', ''])
      sf_accounts.each do |sf_account|
        #GroupAccount Work
        existing_group_account = GroupAccount.find_by_salesforce_id(sf_account.id)
        if sf_account.account_type__c.include? 'Reseller'
          if existing_group_account.blank?
            existing_group_account = GroupAccount.new
            existing_group_account.salesforce_id = sf_account.id
          end
          existing_group_account.name = sf_account.name
          existing_group_account.status = sf_account.account_status__c
          existing_group_account.save
        end
        
        #Account Work
        existing_account = Account.find_by_salesforce_id(sf_account.id)
        if existing_account.blank?
          existing_account = Account.new
          existing_account.salesforce_id = sf_account.id
          existing_account.time_zone = "Central Time (US & Canada)"
        end
        existing_account.account_type = sf_account.account_type__c
        existing_account.status = sf_account.account_status__c
        existing_account.name = sf_account.name
        existing_account.street = sf_account.billing_street
        existing_account.city = sf_account.billing_city
        existing_account.county = sf_account.county__c
        existing_account.state = sf_account.billing_state
        existing_account.postal_code = sf_account.billing_postal_code
        existing_account.country = sf_account.billing_country
        existing_account.phone = sf_account.phone
        existing_account.other_phone = sf_account.other_phone_number__c
        existing_account.fax = sf_account.fax
        existing_account.metro_area = sf_account.metro_area__c
        existing_account.website = sf_account.website
        existing_account.industry = sf_account.industry
        existing_account.main_contact = sf_account.main_contact__c
        existing_account.receive_weekly_report = sf_account.receive_weekly_report__c
        existing_account.reporting_emails = sf_account.email_reports_to__c
        # if sf_account.owner_id.present?
        #   account_manager = Salesforce::User.find(sf_account.owner_id)
        #   existing_account.account_manager = account_manager.name if account_manager.present?
        # end
        if existing_group_account.present?
          existing_account.group_account_id = existing_group_account.id
        else
          reseller = sf_account.parent_id.present? ? GroupAccount.find_by_salesforce_id(sf_account.parent_id) : cityvoice_group_account
          if reseller.present?
            if sf_account.account_type__c.include? 'Reseller'
              existing_account.group_account_id = reseller.id
            else
              existing_account.group_account_id = cityvoice_group_account.id
            end
          end
        end
        
        existing_account.save
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end
end
