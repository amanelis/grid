class GroupAccount < ActiveRecord::Base
  
  has_many :accounts, :dependent => :destroy
  has_many :group_users, :dependent => :destroy
  belongs_to :owner, :class_name => "GroupUser"

  validates_uniqueness_of :name, :case_sensitive => false
  
  
  # TESTING METHODS
  
  def self.print_account_structure
    GroupAccount.all.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |gaccount|
      puts 'Group Account:' + gaccount.name
      accounts = gaccount.accounts
      accounts.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |account|
        puts '------' + account.name
      end
    end
  end
  
  def self.print_total_structure
    GroupAccount.all.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |gaccount|
      puts "Group Account:#{gaccount.name}"
      puts "  Accounts" 
      gaccount.accounts.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |account|
        puts "  #{account.name} is #{account.status}"
        puts "    Campaigns" if account.campaigns.present?
        account.campaigns.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |campaign|
          puts "    #{campaign.name} is #{campaign.status}"
          puts "      Contact Forms" if campaign.contact_forms.present?
          campaign.contact_forms.sort {|a,b| a.id <=> b.id}.each do |contact_form|
            puts "        #{contact_form.description} - #{contact_form.id} - #{contact_form.forwarding_email}"
          end
          puts "      Phone Numbers" if campaign.phone_numbers.present?
          campaign.phone_numbers.sort {|a,b| a.name.downcase <=> b.name.downcase}.each do |phone_number|
            puts "        #{phone_number.name} - #{phone_number.inboundno} is #{phone_number.active}"
          end
          puts "      Website" if campaign.website.present?
          puts "        #{campaign.website.nickname}" if campaign.website.present?         
        end
      end
    end
    nil
  end

  
  # CLASS BEHAVIOR
  
  def self.cache_results_for_group_accounts
    Rails.cache.write("dashboard_dates", self.dashboard_dates)
    Rails.cache.write("dashboard_data_hash", self.dashboard_data_hash)
    Rails.cache.write("accounts_data", Account.get_accounts_data)
  end

  def self.dashboard_dates
    Rails.env.development? ? (Date.yesterday..Date.today).to_a : ((Date.today - 1.month)..Date.today).to_a
  end
  
  def self.dashboard_data_hash
    dashboard_data_hash = self.all.inject({}) { |results, group_account| results[group_account.id] = self.dashboard_dates.inject([]) { |leads, date| leads << group_account.accounts.active.to_a.sum { |account| account.campaigns.active.managed.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) } } }; results }
    dashboard_data_hash[:admin] = self.dashboard_dates.inject([]) { |leads, date| leads << Account.all.to_a.sum { |account| account.campaigns.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) } } }    
    dashboard_data_hash
  end
  
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
    puts "Updating SEO/Ginza Websites"
    SeoCampaign.update_websites_with_ginza
    puts "Updating SEO/Ginza Keywords & Rankings"
    SeoCampaign.update_website_keywords_with_ginza
    # puts "Updating Keyword Rankings..."
    # Keyword.update_keyword_rankings
    # puts "Updating Inbound Links"
    # SeoCampaign.update_inbound_links
    # puts "Updating Website Analyses"
    # SeoCampaign.update_website_analyses
    puts "Updating Map Keywords"
    MapKeyword.update_keywords_from_salesforce
    puts "Updating Map Keyword Rankings"
    MapKeyword.update_map_rankings
    puts 'Updating Adwords Campaign Level Reports'
    GoogleSemCampaign.update_google_sem_campaign_reports_by_campaign
    puts 'Updating Adwords Ad Level Reports'
    GoogleSemCampaign.update_google_sem_campaign_reports_by_ad
    puts 'Updating DailyForecast.update_temperatures'
    DailyForecast.update_temperatures
  end
  
  def self.pull_salesforce_accounts
    job_status = JobStatus.create(:name => "GroupAccount.pull_salesforce_accounts")
    begin
      self.pull_salesforce_reseller_accounts
      cityvoice_account = Account.find_by_name("CityVoice")
      cityvoice_group_account = GroupAccount.find_by_name("CityVoice")
      
      if cityvoice_group_account.blank?
        sf_cityvoice_account = Salesforce::Account.find(:all, :conditions => ['name = ?', 'CityVoice']).first
        cityvoice_group_account = GroupAccount.new
        cityvoice_group_account.salesforce_id = sf_cityvoice_account.id
        cityvoice_group_account.name = sf_cityvoice_account.name
        cityvoice_group_account.status = sf_cityvoice_account.account_status__c
        cityvoice_group_account.save!
      end
        
      sf_accounts = Salesforce::Account.find(:all, :conditions => ['account_status__c != ?', ''])
      sf_accounts.each do |sf_account|
        
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
        existing_account.group_account = cityvoice_group_account
                
        if (account_as_existing_group_account = GroupAccount.find_by_salesforce_id(sf_account.id)).present?
          existing_account.group_account = account_as_existing_group_account
        else
          reseller_group_account = sf_account.parent_id.present? ? GroupAccount.find_by_salesforce_id(sf_account.parent_id) : cityvoice_group_account
          existing_account.group_account = reseller_group_account if reseller_group_account.present?
        end

        if sf_account.owner_id.present?
          sf_account_manager = Salesforce::User.find(sf_account.owner_id)
          if sf_account_manager.present?
            possible_account_managers = GroupUser.find_all_by_email(sf_account_manager.email)
            account_manager = possible_account_managers.detect { |account_manager| account_manager.group_account == existing_account.group_account }
            existing_account.account_manager = account_manager if account_manager.present?
          end
        end
        
        existing_account.save!
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end
  
  def self.pull_salesforce_reseller_accounts
     sf_reseller_accounts = Salesforce::Account.find(:all, :conditions => ['account_type__c = ?', "Reseller"])
     sf_reseller_accounts.each do |sf_reseller_account|
       existing_account = GroupAccount.find_by_salesforce_id(sf_reseller_account.id)
       if existing_account.blank?
         existing_account = GroupAccount.new
         existing_account.salesforce_id = sf_reseller_account.id
       end
       existing_account.name = sf_reseller_account.name
       existing_account.status = sf_reseller_account.account_status__c
       existing_account.save!
     end
   end
   
   
   # INITIALIZATION

   def after_initialize
     self.name ||= ""
     self.salesforce_id ||= ""
   end


   # INSTANCE BEHAVIOR
   
   def managed_campaign_flavors
     Campaign::MANAGED_FLAVORS
   end
         
end
