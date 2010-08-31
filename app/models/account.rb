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
      existing_account = Account.find_by_salesforce_id(sf_account.id)
      if existing_account.blank?
        existing_account = Account.new
        existing_account.salesforce_id = sf_account.id
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
      existing_account.save
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

  def sem_number_of_total_leads_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.sem.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def sem_clicks_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.sem.to_a.sum { |campaign| campaign.campaign_style.clicks_between(start_date, end_date) }
  end

  def sem_impressions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.sem.to_a.sum { |campaign| campaign.campaign_style.impressions_between(start_date, end_date) }
  end

  def sem_click_through_rate_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (count = self.campaigns.sem.count) > 0 ? self.campaigns.sem.to_a.sum { |campaign| campaign.campaign_style.click_through_rate_between(start_date, end_date) } / count : 0.0
  end

  def sem_average_position_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (count = self.campaigns.sem.count) > 0 ? self.campaigns.sem.to_a.sum { |campaign| campaign.campaign_style.average_position_between(start_date, end_date) } / count : 0.0
  end

  def sem_spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.sem.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def seo_spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.seo.to_a.sum { |campaign| campaign.spend_between(start_date, end_date) }
  end

  def seo_number_of_total_leads_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.seo.to_a.sum { |campaign| campaign.number_of_total_leads_between(start_date, end_date) }
  end

  def seo_number_of_actions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.seo.to_a.sum { |campaign| campaign.number_of_actions_between(start_date, end_date) }
  end

  def seo_number_of_average_actions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.seo.to_a.sum { |campaign| campaign.number_of_average_actions_between(start_date, end_date) }
  end

  def seo_number_of_visits_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.seo.to_a.sum { |campaign| campaign.number_of_visits_between(start_date, end_date) }
  end

  def maps_number_of_visits_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaigns.maps.to_a.sum { |campaign| campaign.number_of_map_visits_between(start_date, end_date) }
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
