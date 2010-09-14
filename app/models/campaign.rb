class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :campaign_style, :polymorphic => true
  has_many :phone_numbers, :dependent => :destroy
  has_many :calls, :through => :phone_numbers, :order => "call_start DESC"
  has_many :contact_forms, :dependent => :destroy
  has_many :submissions, :through => :contact_forms
  has_and_belongs_to_many :websites, :uniq => true
  has_and_belongs_to_many :industries

  named_scope :seo, :conditions => {:campaign_style_type => SeoCampaign.name}
  named_scope :sem, :conditions => {:campaign_style_type => SemCampaign.name}
  named_scope :maps, :conditions => {:campaign_style_type => MapsCampaign.name}

  before_destroy :remove_from_many_to_many_relationships

  # CLASS BEHAVIOR

  def self.pull_salesforce_campaigns
    job_status = JobStatus.create(:name => "Campaign.pull_salesforce_campaigns")
    begin
      sf_campaigns = Salesforce::Clientcampaign.all

      sf_campaigns.each do |sf_campaign|
        account = Account.find_by_salesforce_id(sf_campaign.account_id__c)
        if account.present?
          existing_campaign = Campaign.find_by_salesforce_id(sf_campaign.id)
          if sf_campaign.campaign_type__c.include? 'SEM'
            if existing_campaign.blank?
              new_sem_campaign = SemCampaign.new
              existing_campaign = new_sem_campaign.build_campaign
              existing_campaign.account_id = account.id
              existing_campaign.salesforce_id = sf_campaign.id

            else
              new_sem_campaign = existing_campaign.campaign_style
            end

            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            existing_campaign.zip_code = sf_campaign.zip_code__c
            new_sem_campaign.monthly_budget = sf_campaign.monthly_budget__c
            new_sem_campaign.rake = sf_campaign.campaign_rake__c
            new_sem_campaign.developer_token = 'HC3GEwJ4LqgyVNeNTenIVw'
            new_sem_campaign.application_token = '-o8E21xqBmVx7CkQ5TfAag'
            new_sem_campaign.user_agent = 'Biz Search Local'
            new_sem_campaign.password = 'brayden11'
            new_sem_campaign.email = 'bizsearchlocal.jon@gmail.com'
            new_sem_campaign.client_email = 'bizsearchlocal.jon@gmail.com'
            new_sem_campaign.environment = 'PRODUCTION'
            new_sem_campaign.save!
            existing_campaign.save

            google_ids = sf_campaign.google_campaign_id__c.present? ? sf_campaign.google_campaign_id__c.split(',') : ''
            google_ids.each do |google_id|
              google_sem_campaign = GoogleSemCampaign.find_by_reference_id(google_id.strip)
              if google_sem_campaign.blank?
                new_google_sem_campaign = new_sem_campaign.google_sem_campaigns.build
                new_google_sem_campaign.reference_id = google_id.strip
              elsif google_sem_campaign.sem_campaign.name == 'CityVoice SEM Orphaned Campaigns'
                google_sem_campaign.sem_campaign_id = new_sem_campaign.id
                google_sem_campaign.save
              end
            end

          elsif sf_campaign.campaign_type__c.include? 'SEO'
            sf_account = Salesforce::Account.find(account.salesforce_id) 
            if existing_campaign.blank?
              new_seo_campaign = SeoCampaign.new
              existing_campaign = new_seo_campaign.build_campaign
              existing_campaign.account_id = account.id
              existing_campaign.salesforce_id = sf_campaign.id
            else
              new_seo_campaign = existing_campaign.campaign_style
            end
            new_seo_campaign.budget = sf_campaign.monthly_budget__c
            new_seo_campaign.cities = ''
            #new_seo_campaign.keywords = campaign.keywords__c
            new_seo_campaign.dns_host = sf_account.dns_host__c
            new_seo_campaign.dns_login = sf_account.dns_login__c
            new_seo_campaign.dns_password = sf_account.dns_password__c
            new_seo_campaign.hosting_site = sf_account.hosting_site__c
            new_seo_campaign.hosting_username = sf_account.hosting_username__c
            new_seo_campaign.hosting_password = sf_account.hosting_password__c
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            existing_campaign.zip_code = sf_campaign.zip_code__c
            new_seo_campaign.save!
            existing_campaign.save

          elsif sf_campaign.campaign_type__c.include? 'Maps'
            if existing_campaign.blank?
              new_maps_campaign = MapsCampaign.new
              existing_campaign = new_maps_campaign.build_campaign
              existing_campaign.account_id = account.id
              existing_campaign.salesforce_id = sf_campaign.id
            else
              new_maps_campaign = existing_campaign.campaign_style
            end
            new_maps_campaign.keywords = sf_campaign.keywords__c
            new_maps_campaign.company_name = sf_campaign.maps_company_name__c
            existing_campaign.zip_code = sf_campaign.zip_code__c
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            new_google_maps_campaign = new_maps_campaign.google_maps_campaigns.build
            new_google_maps_campaign.login = sf_campaign.maps_login__c
            new_google_maps_campaign.password = sf_campaign.maps_password__c
            new_maps_campaign.save!
            existing_campaign.save

          else
            if existing_campaign.blank?
              new_other_campaign = OtherCampaign.new
              existing_campaign = new_other_campaign.build_campaign
              existing_campaign.account_id = account.id
              existing_campaign.salesforce_id = sf_campaign.id
            else
              new_other_campaign = existing_campaign.campaign_style
            end
            existing_campaign.zip_code = sf_campaign.zip_code__c
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            new_other_campaign.save!
            existing_campaign.save
          end
        end
      end
    rescue Exception =>ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
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

  def self.fix_sf_campaign_ids
    sf_campaigns = Salesforce::Clientcampaign.all
    sf_campaigns.each do |sf_campaign|
      account = Account.find_by_salesforce_id(sf_campaign.account_id__c)
      if account.present?
        existing_campaign = Campaign.find_by_account_id_and_name(account.id, sf_campaign.name)
        if existing_campaign.present?
          existing_campaign.salesforce_id = sf_campaign.id
          existing_campaign.save
        end
      end
    end
  end

  def self.fix_duplicates
    after_date = Date.new(2010, 9, 1)
    campaigns = Campaign.find(:all, :conditions => ['created_at > ?', after_date])
    styles = campaigns.collect {|campaign| campaign.campaign_style}
    styles.each do |style|
      style.destroy
    end
  end

  # INSTANCE BEHAVIOR

  def website
    self.websites.first
  end

  def number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.number_of_lead_calls_between(start_date, end_date) + self.number_of_submissions_between(start_date, end_date)
  end

  def spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaign_style.respond_to?(:spend_between) ? self.campaign_style.spend_between(start_date, end_date) : 0.0
  end

  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaign_style.respond_to?(:cost_between) ? self.campaign_style.cost_between(start_date, end_date) : 0.0
  end

  def cost_per_lead_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_leads : 0.0
  end

  def number_of_answered_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.answered.between(start_date, end_date).count
  end

  def number_of_canceled_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.canceled.between(start_date, end_date).count
  end

  def number_of_voicemail_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.voicemail.between(start_date, end_date).count
  end

  def number_of_other_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.other.between(start_date, end_date).count
  end

  def number_of_lead_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.lead.between(start_date, end_date).count
  end

  def number_of_all_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.between(start_date, end_date).count
  end

  def number_of_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.between(start_date, end_date).count
  end

  def number_of_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:visits_between, start_date, end_date) || 0
  end

  def number_of_map_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:map_visits_between, start_date, end_date) || 0
  end

  def number_of_actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:actions_between, start_date, end_date) || 0
  end

  def number_of_average_actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:average_actions_between, start_date, end_date) || 0.0
  end

  def total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:total_time_spent_between, start_date, end_date) || 0
  end

  def average_total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:average_total_time_spent_between, start_date, end_date) || 0.0
  end

  def bounce_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:bounce_rate_between, start_date, end_date) || 0.0
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
    self.number_of_specific_submissions_labeled_by_date(self.submissions, :submissions)
  end

  def number_of_specific_submissions_labeled_by_date(specific_submissions, label)
    specific_submissions.count(:group => "date(time_of_submission)", :order =>"time_of_submission ASC").inject({}) { |data, (key, value)| data[key.to_date] = {label => value}; data }
  end

  def number_of_leads_by_date
    calls_as_leads = self.number_of_specific_calls_labeled_by_date(self.calls.lead, :leads)
    submissions_as_leads = self.number_of_specific_submissions_labeled_by_date(self.submissions, :leads)
    Utilities.merge_and_sum_timeline_data([calls_as_leads, submissions_as_leads], :leads)
  end

  def call_timeline_data
    Utilities.merge_timeline_data(self.number_of_answered_calls_by_date, self.number_of_canceled_calls_by_date, self.number_of_voicemail_calls_by_date, self.number_of_other_calls_by_date)
  end

  def number_of_visits_by_date
    self.website.try(:number_of_visits_by_date) || {}
  end

  def number_of_map_visits_by_date
    self.website.try(:number_of_map_visits_by_date) || {}
  end

  def remove_from_many_to_many_relationships
    self.websites.each { |website| website.campaigns.delete(self) }
    self.industries.each { |industry| industry.campaigns.delete(self) }
  end


  # PREDICATES

  def is_seo?
    self.campaign_style.instance_of?(SeoCampaign)
  end

  def is_sem?
    self.campaign_style.instance_of?(SemCampaign)
  end

  def is_maps?
    self.campaign_style.instance_of?(MapsCampaign)
  end

  def is_other?
    self.campaign_style.instance_of?(OtherCampaign)
  end

end
