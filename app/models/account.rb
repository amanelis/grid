class Account < ActiveRecord::Base
  has_many :campaigns
  has_one :adwords_client


  # CLASS BEHAVIOR

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

  def self.combined_timeline_data
    raw_data = Utilities.merge_and_sum_timeline_data(Account.all.collect { |account| account.number_of_visits_by_date }, :visits)
    Utilities.massage_timeline(raw_data, [:visits])
  end


  # INSTANCE BEHAVIOR

  def number_of_visits_by_date
     Utilities.merge_and_sum_timeline_data(self.campaigns.collect { |campaign| campaign.campaign_style.number_of_visits_by_date }, :visits)
  end

  def combined_timeline_data
    raw_data = self.number_of_visits_by_date
    Utilities.massage_timeline(raw_data, [:visits])
  end


  # NOTE...these methods don't really make sense at this level in the hierarchy.

  def number_of_total_leads_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def cost_per_lead_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_leads : 0.0
  end

  def number_of_answered_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_answered_calls_between(start_date, end_date) }
  end

  def number_of_canceled_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_canceled_calls_between(start_date, end_date) }
  end

  def number_of_voicemail_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_voicemail_calls_between(start_date, end_date) }
  end

  def number_of_other_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_other_calls_between(start_date, end_date) }
  end

  def number_of_all_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_all_calls_between(start_date, end_date) }
  end

  def number_of_submissions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.to_a.sum { |campaign| campaign.number_of_submissions_between(start_date, end_date) }
  end

end
