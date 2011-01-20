class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :campaign_style, :polymorphic => true
  belongs_to :website
  has_many :phone_numbers, :dependent => :destroy
  has_many :calls, :through => :phone_numbers, :order => "call_start DESC"
  has_many :contact_forms, :dependent => :destroy
  has_many :submissions, :through => :contact_forms, :order => "time_of_submission DESC"
  has_and_belongs_to_many :industries

  named_scope :active, :conditions => ['LCASE(status) = ? OR LCASE(status) = ?', "active", "paused"], :order => "name ASC"
  named_scope :seo, :conditions => {:campaign_style_type => SeoCampaign.name}
  named_scope :sem, :conditions => {:campaign_style_type => SemCampaign.name}
  named_scope :maps, :conditions => {:campaign_style_type => MapsCampaign.name}
  named_scope :other, :conditions => {:campaign_style_type => OtherCampaign.name}
  
  named_scope :cityvoice, :conditions => ["LCASE(flavor) IN ('seo', 'sem - all', 'sem - bing', 'sem - google', 'sem - google boost', 'sem - google mobile', 'sem - yahoo', 'local maps', 'retargeter')"]
  named_scope :unmanaged, :conditions => ["LCASE(flavor) NOT IN ('seo', 'sem - all', 'sem - bing', 'sem - google', 'sem - google boost', 'sem - google mobile', 'sem - yahoo', 'local maps', 'retargeter')"]

  before_destroy :remove_from_many_to_many_relationships

  attr_accessor :adopting_phone_number

  ORPHANAGE_NAME = 'CityVoice SEM Orphaned Campaigns'
  
  CITYVOICE_MANAGED_FLAVORS = ['seo', 'sem - all', 'sem - bing', 'sem - google', 'sem - google boost', 'sem - google mobile', 'sem - yahoo', 'local maps', 'retargeter']
  
  
  # Twilio REST API version
  API_VERSION = '2010-04-01'

  # Twilio AccountSid and AuthToken
  ACCOUNT_SID = 'AC7fedbe5d54f77671320418d20f843330'
  ACCOUNT_TOKEN = 'a7a72b0eb3c8a41064c4fc741674a903'
  
  # CLASS BEHAVIOR

  def self.orphanage
    Campaign.find_by_name(ORPHANAGE_NAME)
  end
  
  def self.flavors
    Campaign.all.collect(&:flavor).compact.join(';').split(';').uniq.sort
  end

  def self.pull_salesforce_campaigns
    job_status = JobStatus.create(:name => "Campaign.pull_salesforce_campaigns")
    begin
      sf_campaigns = Salesforce::Clientcampaign.all

      sf_campaigns.each do |sf_campaign|
        next if sf_campaign.campaign_type__c.blank?

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
              unless new_sem_campaign.instance_of?(SemCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_sem_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            existing_campaign.zip_code = sf_campaign.zip_code__c
            existing_campaign.flavor = sf_campaign.campaign_type__c
            new_sem_campaign.mobile = true if sf_campaign.campaign_type__c.include? 'Mobile'
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
              elsif google_sem_campaign.sem_campaign.name == ORPHANAGE_NAME
                google_sem_campaign.sem_campaign_id = new_sem_campaign.id
                google_sem_campaign.save
              elsif google_sem_campaign.sem_campaign_id != new_sem_campaign.id
                google_sem_campaign.sem_campaign_id = new_sem_campaign.id
                google_sem_campaign.save
                puts "#{google_sem_campaign.name} reassigned from #{google_sem_campaign.sem_campaign.name} to #{new_sem_campaign.name}"
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
              unless new_seo_campaign.instance_of?(SeoCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_seo_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
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
            existing_campaign.flavor = sf_campaign.campaign_type__c
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
              unless new_maps_campaign.instance_of?(MapsCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_maps_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            new_maps_campaign.keywords = sf_campaign.keywords__c
            new_maps_campaign.company_name = sf_campaign.maps_company_name__c
            existing_campaign.zip_code = sf_campaign.zip_code__c
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            existing_campaign.flavor = sf_campaign.campaign_type__c
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
              unless new_other_campaign.instance_of?(OtherCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_other_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            existing_campaign.zip_code = sf_campaign.zip_code__c
            existing_campaign.status = sf_campaign.status__c
            existing_campaign.name = sf_campaign.name
            existing_campaign.flavor = sf_campaign.campaign_type__c
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
    styles = campaigns.collect { |campaign| campaign.campaign_style }
    styles.each do |style|
      style.destroy
    end
  end
  
  def self.determine_totals_for(campaigns, messages, start_date = Date.yesterday, end_date = Date.yesterday)
    messages.inject({}) { |results, message| results[message] = campaigns.sum { |campaign| campaign.send(message, start_date, end_date) } ; results }
  end
  
  def self.weighted_cost_per_lead_for(campaigns, start_date = Date.yesterday, end_date = Date.yesterday)
    weighted_total = 0.0
    total_weight = 0.0
    campaigns.each do |campaign|
      total_weight += (weight = campaign.number_of_total_leads_between(start_date, end_date))
      weighted_total += (campaign.cost_per_lead_between(start_date, end_date) * weight)
    end
    total_weight > 0 ? weighted_total / total_weight : 0.0 
  end

  def self.weighted_cost_per_contact_for(campaigns, start_date = Date.yesterday, end_date = Date.yesterday)
    weighted_total = 0.0
    total_weight = 0.0
    campaigns.each do |campaign|
      total_weight += (weight = campaign.number_of_total_contacts_between(start_date, end_date))
      weighted_total += (campaign.cost_per_contact_between(start_date, end_date) * weight)
    end
    total_weight > 0 ? weighted_total / total_weight : 0.0 
  end


  # INSTANCE BEHAVIOR

  def adopting_phone_number
    @adopting_phone_number
  end

  def number_of_total_leads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.number_of_lead_calls_between(start_date, end_date) + self.number_of_lead_submissions_between(start_date, end_date)
  end

  def number_of_total_contacts_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.number_of_all_calls_between(start_date, end_date) + self.number_of_all_submissions_between(start_date, end_date)
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

  def cost_per_contact_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_contacts = self.number_of_total_contacts_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date) / total_contacts : 0.0
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

  def number_of_unique_calls_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.calls.unique.between(start_date, end_date).count
  end

  def number_of_lead_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.lead.between(start_date, end_date).count
  end

  def number_of_all_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.between(start_date, end_date).count
  end

  def number_of_non_spam_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.non_spam.between(start_date, end_date).count
  end

  def total_revenue_between(start_date = Date.yesterday, end_date = Date.yesterday)
    Call.total_revenue(self.calls.between(start_date, end_date))
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

  def number_of_bounces_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website.try(:bounces_between, start_date, end_date) || 0
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

  def number_of_lead_submissions_by_date
    self.number_of_specific_submissions_labeled_by_date(self.submissions.lead, :submissions)
  end

  def number_of_specific_submissions_labeled_by_date(specific_submissions, label)
    specific_submissions.count(:group => "date(time_of_submission)", :order =>"time_of_submission ASC").inject({}) { |data, (key, value)| data[key.to_date] = {label => value}; data }
  end

  def number_of_leads_by_date
    calls_as_leads = self.number_of_specific_calls_labeled_by_date(self.calls.lead, :leads)
    submissions_as_leads = self.number_of_specific_submissions_labeled_by_date(self.submissions.lead, :leads)
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

  def contact_form_id_string
    self.contact_forms.collect { |x| x.id.to_s }.join(", ")
  end

  def contact_form_emails_string
    self.contact_forms.collect { |x| x.forwarding_email }.join(", ")
  end

  def create_website(website, mirrors = '', time_zone = "-6")
    if self.website.present?
      return "This Campaign already has a website!\nClicky Code:<script src=\"http://stats.cityvoice.com/js\" type=\"text/javascript\"></script><script type=\"text/javascript\">citystats.init(#{self.website.site_id});</script><noscript><p><img alt=\"CityStats\" width=\"1\" height=\"1\" src=\"http://stats.cityvoice.com/#{self.website.site_id}ns.gif\" /></p></noscript>"
    end
    
    website = website.gsub("http://",  "").gsub("https://", "")
    existing_website = Website.find_by_nickname(website)
    
    if existing_website.present?
      self.website_id = existing_website.id
      self.save
      return "Website already exists on another campaign!\nClick Code: <script src=\"http://stats.cityvoice.com/js\" type=\"text/javascript\"></script><script type=\"text/javascript\">citystats.init(#{existing_website.site_id});</script><noscript><p><img alt=\"CityStats\" width=\"1\" height=\"1\" src=\"http://stats.cityvoice.com/#{existing_website.site_id}ns.gif\" /></p></noscript>"
    end
      
    url = "https://api.getclicky.com/api/account/sites?username=cityvoicesa&password=C1tyv01c3&output=json"
    exists_on_clicky = false
    site_id = sitekey = database_server = admin_sitekey = ''
    successfuly_found_or_added = false
    
    HTTParty.get(url).each do |site|
      if site["nickname"] == website
        exists_on_clicky = true
        site_id = site["site_id"] 
        sitekey = site["sitekey"]
        database_server = ''
        admin_sitekey = site["sitekey_admin"]
        successfuly_found_or_added = true
      end
    end
    
    unless exists_on_clicky
      url = "http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/?auth=de8f1bae61c60eb0&type=site&user_id=134255&domain=#{website}&nickname=#{website}&timezone=#{time_zone}&dst=usa"
      url += "&mirrors=#{mirrors}" if mirrors.present?
      info = HTTParty.get(url).parsed_response.split("\n")
      if info.first == 'OK'
        site_id = info[1]
        sitekey = info[2]
        database_server = info[3]
        admin_sitekey = info[4]
        successfuly_found_or_added = true
      end
    end
    
    if successfuly_found_or_added
      new_website = Website.new
      new_website.is_active = true
      new_website.nickname = website
      new_website.domain = website
      new_website.site_id = site_id
      new_website.sitekey = sitekey
      new_website.database_server = database_server
      new_website.admin_sitekey = admin_sitekey
      new_website.timezone = time_zone
      new_website.mirrors = mirrors
      new_website.dst = "dst"
      new_website.save
      self.website_id = new_website.id
      self.save!
      return "Website was created!\nClick Code: <script src=\"http://stats.cityvoice.com/js\" type=\"text/javascript\"></script><script type=\"text/javascript\">citystats.init(#{site_id});</script><noscript><p><img alt=\"CityStats\" width=\"1\" height=\"1\" src=\"http://stats.cityvoice.com/#{site_id}ns.gif\" /></p></noscript>"
    end
    
    "Website was not added due to errors"
  end

  def delete_website()
    return "There is no website on this campaign" if self.website.blank?
    if self.website.campaigns.count > 1 || HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/?auth=de8f1bae61c60eb0&type=site&site_id=#{self.website.site_id}&delete=1").parsed_response.split("\n").first == 'OK'
      self.website_id = nil
      self.save
      "Your site was deleted."
    else
      "There was an error deleting your site."
    end
  end
  
  def create_twilio_number(phone_number, name, forward_to, id_caller = true, record_calls = true, transcribe_calls = false, text_calls = false, call_url = "http://grid.cityvoice.com/phone_numbers/connect/", fallback_url = "http://grid.cityvoice.com/phone_numbers/connect/", status_url = "http://grid.cityvoice.com/phone_numbers/collect/", sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/", fallback_sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/")
    job_status = JobStatus.create(:name => "Campaign.create_twilio_number")
    begin
      #CREATE THE NUMBER IN TWILIO (BASIC INFORMATION)
      account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
      d = {}
      d['PhoneNumber'] = '+1' + phone_number if phone_number.length == 10
      d['PhoneNumber'] = '+' + phone_number if phone_number.length == 11
      d['AreaCode'] = phone_number if phone_number.length == 3
      resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers.json", 'POST', d)
      raise unless resp.kind_of? Net::HTTPSuccess
      
      #CREATE THE PHONE NUMBER IN GRID IF TWILIO CREATION WAS SUCCESSFUL
      if resp.code == '200' || resp.code == '201'
        new_phone_number = self.phone_numbers.build
        new_phone_number.twilio_id = JSON.parse(resp.body)['sid']
        new_phone_number.inboundno = phone_number.to_s
        new_phone_number.forward_to = forward_to
        new_phone_number.name = name
        new_phone_number.descript = name
        new_phone_number.twilio_version = API_VERSION
        new_phone_number.id_callers = id_caller
        new_phone_number.record_calls = record_calls
        new_phone_number.transcribe_calls = transcribe_calls
        new_phone_number.text_calls = text_calls
        new_phone_number.active = true
        new_phone_number.save
        #UPDATE THE TWILIO URLS
        new_phone_number.update_twilio_number(name, forward_to, id_caller, record_calls, transcribe_calls, text_calls, call_url, fallback_url, status_url, sms_url, fallback_sms_url)
        job_status.finish_with_no_errors
        return new_phone_number
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
  end
  
  def inactivate_phone_number(phone_number_id)
    phone_number = self.phone_numbers.first(:conditions => ['id = ?', phone_number_id])
    return false if phone_number.blank?
    if phone_number.twilio_id.present?
      account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
      resp = account.request("/#{phone_number.twilio_version}/Accounts/#{ACCOUNT_SID}/IncomingPhoneNumbers/#{phone_number.twilio_id}.json", 'DELETE')
      if resp.code == '204'
        phone_number.active = false
        phone_number.save
        return true
      else
        return false
      end
    end
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
  
  def cityvoice_managed?
    CITYVOICE_MANAGED_FLAVORS.include?(self.flavor.downcase)
  end
  
  
  # PRIVATE BEHAVIOR

  private

  def remove_from_many_to_many_relationships
    self.industries.each { |industry| industry.campaigns.delete(self) }
  end

end
