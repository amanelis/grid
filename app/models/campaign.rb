class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :campaign_style, :polymorphic => true
  has_many :phone_numbers
  has_many :calls, :through => :phone_numbers
  has_many :contact_forms
  has_many :submissions, :through => :contact_forms
  has_and_belongs_to_many :websites
  has_and_belongs_to_many :industries


  # CLASS BEHAVIOR

  def self.pull_salesforce_campaigns
    sf_campaigns = Salesforce::Clientcampaign.all

    sf_campaigns.each do |sf_campaign|
      account = Account.find_by_salesforce_id(sf_campaign.account_id__c)
      if account.present?
        unless Campaign.exists?(:account_id => account.id, :name => sf_campaign.name)
          if sf_campaign.campaign_type__c.include? 'SEM'
            new_sem_campaign = SemCampaign.new
            new_sem_campaign.monthly_budget = sf_campaign.monthly_budget__c
            new_sem_campaign.rake = sf_campaign.campaign_rake__c
            new_sem_campaign.developer_token = 'HC3GEwJ4LqgyVNeNTenIVw'
            new_sem_campaign.application_token = '-o8E21xqBmVx7CkQ5TfAag'
            new_sem_campaign.user_agent = 'Biz Search Local'
            new_sem_campaign.password = 'brayden11'
            new_sem_campaign.email = 'bizsearchlocal.jon@gmail.com'
            new_sem_campaign.client_email = 'bizsearchlocal.jon@gmail.com'
            new_sem_campaign.environment = 'PRODUCTION'
            new_campaign = new_sem_campaign.build_campaign
            new_campaign.account_id = account.id
            new_campaign.status = sf_campaign.status__c
            new_campaign.name = sf_campaign.name

            google_ids = sf_campaign.google_campaign_id__c.present? ? sf_campaign.google_campaign_id__c.split(',') : ''
            google_ids.each do |google_id|
              new_google_sem_campaign = new_sem_campaign.google_sem_campaigns.build
              new_google_sem_campaign.reference_id = google_id.gsub(' ', '')
            end
            new_sem_campaign.save!


          elsif sf_campaign.campaign_type__c.include? 'SEO'
            sf_account = Salesforce::Account.find(account.salesforce_id)
            new_seo_campaign = SeoCampaign.new
            new_seo_campaign.budget = sf_campaign.monthly_budget__c
            new_seo_campaign.cities = ''
            #new_seo_campaign.keywords = campaign.keywords__c
            new_seo_campaign.dns_host = sf_account.dns_host__c
            new_seo_campaign.dns_login = sf_account.dns_login__c
            new_seo_campaign.dns_password = sf_account.dns_password__c
            new_seo_campaign.hosting_site = sf_account.hosting_site__c
            new_seo_campaign.hosting_username = sf_account.hosting_username__c
            new_seo_campaign.hosting_password = sf_account.hosting_password__c

            new_campaign = new_seo_campaign.build_campaign
            new_campaign.account_id = account.id
            new_campaign.status = sf_campaign.status__c
            new_campaign.name = sf_campaign.name

            new_seo_campaign.save!

          elsif sf_campaign.campaign_type__c.include? 'Maps'
            new_maps_campaign = MapsCampaign.new
            new_maps_campaign.keywords = sf_campaign.keywords__c
            new_maps_campaign.company_name = sf_campaign.maps_company_name__c

            new_campaign = new_maps_campaign.build_campaign
            new_campaign.account_id = account.id
            new_campaign.status = sf_campaign.status__c
            new_campaign.name = sf_campaign.name

            new_google_maps_campaign = new_maps_campaign.google_maps_campaigns.build
            new_google_maps_campaign.login = sf_campaign.maps_login__c
            new_google_maps_campaign.password = sf_campaign.maps_password__c

            new_maps_campaign.save!
          end
        end
      end
    end
  end

  def self.fix_target_cities
    campaigns = Campaign.all
    campaigns.each do |campaign|
      if campaign.target_cities.blank?
        campaign.target_cities = campaign.account.city.downcase if campaign.account.city.present?
        campaign.save
      end
    end
  end

  # INSTANCE BEHAVIOR

  def number_of_total_leads_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.number_of_lead_calls_between(start_date, end_date) + self.number_of_submissions_between(start_date, end_date)
  end

  def spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.campaign_style.respond_to?(:spend_between) ? self.campaign_style.spend_between(start_date, end_date) : 0.0
  end

  def cost_per_lead_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_leads : 0.0
  end

  def number_of_answered_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.answered.between(start_date, end_date).count
  end

  def number_of_canceled_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.canceled.between(start_date, end_date).count
  end

  def number_of_voicemail_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.voicemail.between(start_date, end_date).count
  end

  def number_of_other_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.other.between(start_date, end_date).count
  end

  def number_of_lead_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.lead.between(start_date, end_date).count
  end

  def number_of_all_calls_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.calls.between(start_date, end_date).count
  end

  def number_of_submissions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.submissions.between(start_date, end_date).count
  end

  def number_of_answered_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.answered, :answered)
  end

  def number_of_canceled_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.canceled, :canceled)
  end

  def number_of_voicemail_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.voicemail, :voicemail)
  end

  def number_of_other_calls_by_date
    self.number_of_specific_calls_labeled_by_date(self.calls.other, :other)
  end

  def number_of_specific_calls_labeled_by_date(specific_calls, label)
    specific_calls.count(:group => "date(call_start)", :order =>"call_start ASC").inject({}) { |data, (key, value)| data[key.to_date] = {label => value}; data }
  end

  def number_of_submissions_by_date
    self.number_of_specific_submissions_labeled_by_date(self.submissions, :submission)
  end

  def number_of_specific_submissions_labeled_by_date(specific_submissions, label)
    specific_submissions.count(:group => "date(time_of_submission)", :order =>"time_of_submission ASC").inject({}) { |data, (key, value)| data[key.to_date] = {label => value}; data }
  end

  def number_of_leads_by_date
    calls_as_leads = self.number_of_specific_calls_labeled_by_date(self.calls.lead, :lead)
    submissions_as_leads = self.number_of_specific_submissions_labeled_by_date(self.submissions, :lead)
    [calls_as_leads, submissions_as_leads].inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| {:lead => v1[:lead] + v2[:lead]} } }
  end

  def call_timeline_data
    Utilities.merge_timeline_data(self.number_of_answered_calls_by_date, self.number_of_canceled_calls_by_date, self.number_of_voicemail_calls_by_date, self.number_of_other_calls_by_date)
  end

  def combined_timeline_data
    Utilities.merge_timeline_data(self.call_timeline_data, self.number_of_submissions_by_date, self.number_of_leads_by_date)
  end

end
