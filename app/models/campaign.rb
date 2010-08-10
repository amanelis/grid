class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :campaign_style, :polymorphic => true
  has_many :phone_numbers
  has_many :contact_forms
  has_and_belongs_to_many :websites


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

            new_campaign = new_sem_campaign.build_campaign
            new_campaign.account_id = account.id
            new_campaign.status = sf_campaign.status__c
            new_campaign.name = sf_campaign.name

            google_ids = sf_campaign.google_campaign_id__c.present? ? sf_campaign.google_campaign_id__c.split(',') : ''
            google_ids.each do |google_id|
              new_google_sem_campaign = new_sem_campaign.google_sem_campaigns.build
              new_google_sem_campaign.google_campaign_id = google_id
              new_google_sem_campaign.developer_token = 'cTCRorA4_W1lVyATKfaPwA'
              new_google_sem_campaign.application_token = '-o8E21xqBmVx7CkQ5TfAag'
              new_google_sem_campaign.user_agent = 'Biz Search Local'
              new_google_sem_campaign.password = 'boze4man!'
              new_google_sem_campaign.email = 'jgwbizsearch@gmail.com'
              new_google_sem_campaign.client_email = 'jgwbizsearch@gmail.com'
              new_google_sem_campaign.environment = 'PRODUCTION'
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
end
