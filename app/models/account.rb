class Account < ActiveRecord::Base
  has_many :campaigns
  has_one :adwords_client

  def visit_count_by_date
    data = {}
    campaigns.each do |campaign|
      campaign.websites.each do |website|
        raw_visits = website.website_visits.count(:all, :group => "date(time_of_visit)", :order =>"time_of_visit ASC")
        raw_visits.each_pair {|key, value| data[key.to_date] = {website.domain.to_sym => value}}
      end
    end
    data
  end

  def self.visit_count_by_date
    WebsiteVisit.count(:group => "date(time_of_visit)", :order =>"time_of_visit ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:web_visits => value} ; data}
  end

  def sorted_dates
    rawdates = JSON.parse(self.daily_timeline.dates)
    data = []
    rawdates.each do |date|
      data << DateTime.strptime( date.to_s, "%Y%m%d")
    end
    data.sort
  end

  def self.sorted_dates
    WebsiteVisit.find(:all, :select => "time_of_visit").inject([]) { |data, date| data << DateTime.strptime(date.time_of_visit.to_s, "%Y-%m-%d") }.sort
   end


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


  # INSTANCE BEHAVIOR

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
