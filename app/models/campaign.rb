class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :channel
  belongs_to :campaign_style, :polymorphic => true
  belongs_to :website
  has_many :phone_numbers, :dependent => :destroy
  has_many :calls, :through => :phone_numbers, :order => "call_start DESC"
  has_many :contact_forms, :dependent => :destroy
  has_many :submissions, :through => :contact_forms, :order => "time_of_submission DESC"
  has_and_belongs_to_many :industries
  
  delegate :time_zone , :to => :account
  
  named_scope :active, :conditions => ['LCASE(status) = ? OR LCASE(status) = ?', "active", "paused"], :order => "name ASC"
  named_scope :seo, :conditions => {:campaign_style_type => SeoCampaign.name}
  named_scope :sem, :conditions => {:campaign_style_type => SemCampaign.name}
  named_scope :maps, :conditions => {:campaign_style_type => MapsCampaign.name}
  named_scope :basic, :conditions => {:campaign_style_type => BasicCampaign.name}
  
  named_scope :new_managed, lambda { |group_account| {:conditions => ["LCASE(flavor) IN (#{group_account.managed_campaign_flavors.inspect[1...-1]})"]} }
  named_scope :new_unmanaged, lambda { |group_account| {:conditions => ["LCASE(flavor) NOT IN (#{group_account.managed_campaign_flavors.inspect[1...-1]})"]} }

  named_scope :managed, lambda { {:conditions => ["LCASE(flavor) IN (#{MANAGED_FLAVORS.inspect[1...-1]})"]} }
  named_scope :unmanaged, lambda { {:conditions => ["LCASE(flavor) NOT IN (#{MANAGED_FLAVORS.inspect[1...-1]})"]} }

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :scope => "account_id"
  validate :proper_channel?

  before_destroy :remove_from_many_to_many_relationships

  attr_accessor :adopting_phone_number

  ORPHANAGE_NAME = 'CityVoice SEM Orphaned Campaigns'
  
  MANAGED_FLAVORS = ['seo', 'sem - all', 'sem - bing', 'sem - google', 'sem - google boost', 'sem - google mobile', 'sem - yahoo', 'local maps', 'retargeter']
  

  # VIRTUAL ATTRIBUTES
  
  def industry=(industry)
    self.industries << Industry.find_by_name(industry)
    self.save!
  end

  def area_code=(area_code)
    self.create_twilio_number(area_code, self.name, self.forwarding_number)
  end

  def forwarding_number
    @forwarding_number
  end
  
  def forwarding_number=(a_forwarding_number)
    @forwarding_number = a_forwarding_number
  end


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

          # SEM CAMPAIGN

          if sf_campaign.campaign_type__c.include? 'SEM'
            if existing_campaign.blank?
              new_sem_campaign = SemCampaign.new
              new_sem_campaign.salesforce_id = sf_campaign.id
            else
              new_sem_campaign = existing_campaign.campaign_style
              unless new_sem_campaign.instance_of?(SemCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_sem_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            new_sem_campaign.account = account
            new_sem_campaign.status = sf_campaign.status__c
            new_sem_campaign.name = sf_campaign.name
            new_sem_campaign.zip_code = sf_campaign.zip_code__c
            new_sem_campaign.flavor = sf_campaign.campaign_type__c
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
            new_sem_campaign.campaign.save!

            google_ids = sf_campaign.google_campaign_id__c.present? ? sf_campaign.google_campaign_id__c.split(',') : ''
            google_ids.each do |google_id|
              google_sem_campaign = GoogleSemCampaign.find_by_reference_id(google_id.strip)
              if google_sem_campaign.blank?
                new_google_sem_campaign = new_sem_campaign.google_sem_campaigns.build
                new_google_sem_campaign.reference_id = google_id.strip
              elsif google_sem_campaign.sem_campaign.name == ORPHANAGE_NAME
                google_sem_campaign.sem_campaign_id = new_sem_campaign.id
                google_sem_campaign.save!
              elsif google_sem_campaign.sem_campaign_id != new_sem_campaign.id
                google_sem_campaign.sem_campaign_id = new_sem_campaign.id
                google_sem_campaign.save!
                puts "#{google_sem_campaign.name} reassigned from #{google_sem_campaign.sem_campaign.name} to #{new_sem_campaign.name}"
              end
            end

          # SEO CAMPAIGN

          elsif sf_campaign.campaign_type__c.include? 'SEO'
            sf_account = Salesforce::Account.find(account.salesforce_id)
            if existing_campaign.blank?
              new_seo_campaign = SeoCampaign.new
              new_seo_campaign.salesforce_id = sf_campaign.id
            else
              new_seo_campaign = existing_campaign.campaign_style
              unless new_seo_campaign.instance_of?(SeoCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_seo_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            new_seo_campaign.account = account
            new_seo_campaign.budget = sf_campaign.monthly_budget__c
            new_seo_campaign.cities = ''
            #new_seo_campaign.keywords = campaign.keywords__c
            new_seo_campaign.dns_host = sf_account.dns_host__c
            new_seo_campaign.dns_login = sf_account.dns_login__c
            new_seo_campaign.dns_password = sf_account.dns_password__c
            new_seo_campaign.hosting_site = sf_account.hosting_site__c
            new_seo_campaign.hosting_username = sf_account.hosting_username__c
            new_seo_campaign.hosting_password = sf_account.hosting_password__c
            new_seo_campaign.status = sf_campaign.status__c
            new_seo_campaign.name = sf_campaign.name
            new_seo_campaign.zip_code = sf_campaign.zip_code__c
            new_seo_campaign.flavor = sf_campaign.campaign_type__c
            new_seo_campaign.save!
            new_seo_campaign.campaign.save!
            
          # MAPS CAMPAIGN

          elsif sf_campaign.campaign_type__c.include? 'Maps'
            if existing_campaign.blank?
              new_maps_campaign = MapsCampaign.new
              new_maps_campaign.salesforce_id = sf_campaign.id
            else
              new_maps_campaign = existing_campaign.campaign_style
              unless new_maps_campaign.instance_of?(MapsCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_maps_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            new_maps_campaign.account = account
            new_maps_campaign.keywords = sf_campaign.keywords__c
            new_maps_campaign.company_name = sf_campaign.maps_company_name__c
            new_maps_campaign.zip_code = sf_campaign.zip_code__c
            new_maps_campaign.status = sf_campaign.status__c
            new_maps_campaign.name = sf_campaign.name
            new_maps_campaign.flavor = sf_campaign.campaign_type__c
            new_google_maps_campaign = new_maps_campaign.google_maps_campaigns.build
            new_google_maps_campaign.login = sf_campaign.maps_login__c
            new_google_maps_campaign.password = sf_campaign.maps_password__c
            new_maps_campaign.save!
            new_maps_campaign.campaign.save!
            
          # BASIC CAMPAIGN

          else
            if existing_campaign.blank?
              new_basic_campaign = BasicCampaign.new
              new_basic_campaign.salesforce_id = sf_campaign.id
            else
              new_basic_campaign = existing_campaign.campaign_style
              unless new_basic_campaign.instance_of?(BasicCampaign)
                logger.debug "\n\n**********************************"
                logger.debug "Campaign Error on #{new_basic_campaign.name}"
                logger.debug "**********************************\n\n"
                next
              end
            end
            new_basic_campaign.account = account
            new_basic_campaign.zip_code = sf_campaign.zip_code__c
            new_basic_campaign.status = sf_campaign.status__c
            new_basic_campaign.name = sf_campaign.name
            new_basic_campaign.flavor = sf_campaign.campaign_type__c
            new_basic_campaign.save!
            new_basic_campaign.campaign.save!
          end
        end
      end
    rescue Exception =>ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
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
  
  def self.true_weighted_cost_per_lead_for(campaigns, start_date = Date.yesterday, end_date = Date.yesterday)
    weighted_total = 0.0
    total_weight = 0.0
    campaigns.each do |campaign|
      total_weight += (weight = campaign.number_of_total_leads_between(start_date, end_date))
      weighted_total += (campaign.true_cost_per_lead_between(start_date, end_date) * weight)
    end
    total_weight > 0 ? weighted_total / total_weight : 0.0 
  end

  def self.true_weighted_cost_per_contact_for(campaigns, start_date = Date.yesterday, end_date = Date.yesterday)
    weighted_total = 0.0
    total_weight = 0.0
    campaigns.each do |campaign|
      total_weight += (weight = campaign.number_of_total_contacts_between(start_date, end_date))
      weighted_total += (campaign.true_cost_per_contact_between(start_date, end_date) * weight)
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
  
  def true_cost_per_lead_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_leads = self.number_of_total_leads_between(start_date, end_date)) > 0 ? self.cost_between(start_date, end_date) / total_leads : 0.0
  end

  def true_cost_per_contact_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (total_contacts = self.number_of_total_contacts_between(start_date, end_date)) > 0 ? self.cost_between(start_date, end_date) / total_contacts : 0.0
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
  
  def most_recent_map_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    self.campaign_style.map_keywords.first.map_rankings.between(start_date, end_date).try(:last)
  end

  def number_of_leads_by_date
    Utilities.merge_and_sum_timeline_data([self.number_of_specific_calls_labeled_by_date(self.calls.lead, :leads), self.number_of_specific_submissions_labeled_by_date(self.submissions.lead, :leads)], :leads)
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
      self.save!
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
      new_website.save!
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
      self.save!
      "Your site was deleted."
    else
      "There was an error deleting your site."
    end
  end
  
  def create_twilio_number(phone_number, name, forward_to, id_callers = true, record_calls = true, transcribe_calls = false, text_calls = false, call_url = "http://grid.cityvoice.com/phone_numbers/connect/", fallback_url = "http://grid.cityvoice.com/phone_numbers/connect/", status_url = "http://grid.cityvoice.com/phone_numbers/collect/", sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/", fallback_sms_url = "http://grid.cityvoice.com/phone_numbers/sms_collect/")
    job_status = JobStatus.create(:name => "Campaign.create_twilio_number")
    begin
      self.account.create_twilio_subaccount if self.account.twilio_id.blank?
      
      # If they get rid of the number need to check to see if there are any more numbers on account object. if there
      # are no numbers delete account.twilio_id
      #self.account.activate_twilio_subaccount
      #CREATE THE NUMBER IN TWILIO (BASIC INFORMATION)
      d = {'PhoneNumber' => "+1#{phone_number}"} if phone_number.length == 10
      d = {'PhoneNumber' => "+#{phone_number}"} if phone_number.length == 11
      d = {'AreaCode' => phone_number} if phone_number.length == 3
      resp = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{API_VERSION}/Accounts/#{self.account.twilio_id}/IncomingPhoneNumbers.json", 'POST', d)
      raise unless resp.kind_of? Net::HTTPSuccess
      
      #CREATE THE PHONE NUMBER IN GRID IF TWILIO CREATION WAS SUCCESSFUL
      new_phone_number = self.phone_numbers.build
      new_phone_number.twilio_id = JSON.parse(resp.body)['sid']
      new_phone_number.inboundno = JSON.parse(resp.body)['phone_number'].gsub("+", "")
      new_phone_number.forward_to = forward_to
      new_phone_number.name = name
      new_phone_number.descript = name
      new_phone_number.twilio_version = API_VERSION
      new_phone_number.id_callers = id_callers
      new_phone_number.record_calls = record_calls
      new_phone_number.transcribe_calls = transcribe_calls
      new_phone_number.text_calls = text_calls
      new_phone_number.active = true
      new_phone_number.save!
      
      #UPDATE THE TWILIO URLS
      new_phone_number.update_twilio_number(new_phone_number.name, new_phone_number.forward_to, new_phone_number.id_callers, new_phone_number.record_calls, new_phone_number.transcribe_calls, new_phone_number.text_calls, call_url, fallback_url, status_url, sms_url, fallback_sms_url)
      job_status.finish_with_no_errors
      return new_phone_number
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
  end
  
  def inactivate_phone_number(phone_number_id)
    phone_number = self.phone_numbers.first(:conditions => ['id = ?', phone_number_id])
    return false if phone_number.blank? || phone_number.twilio_id.blank?
    resp = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN).request("/#{phone_number.twilio_version}/Accounts/#{self.account.twilio_id}/IncomingPhoneNumbers/#{phone_number.twilio_id}.json", 'DELETE')
    return false unless resp.code == '204'
    phone_number.active = false
    phone_number.save!
    true
  end
  
  def create_contact_form(description = '',  forwarding_email = '', forwarding_bcc_email = '', custom1_text = '', custom2_text = '', custom3_text = '', custom4_text = '', need_name = true, need_address = true, need_phone = true, need_email = true, work_category = true, work_description = true, date_requested = true, time_requested = true, other_information = true)
    form = self.contact_forms.build
    form.return_url = 'http://grid.cityvoice.com/thank_you'
    form.forwarding_email = forwarding_email
    form.forwarding_bcc_email = forwarding_bcc_email
    form.custom1_text = custom1_text
    form.custom2_text = custom2_text
    form.custom3_text = custom3_text
    form.custom4_text = custom4_text
    form.need_name = need_name
    form.need_address = need_address
    form.need_phone = need_phone
    form.need_email = need_email
    form.work_category = work_category
    form.work_description = work_description
    form.date_requested = date_requested
    form.time_requested = time_requested
    form.other_information = other_information
    form.save
    form.html_block = form.get_form_text
    form.return_url = "http://grid.cityvoice.com/contact_forms/#{form.id}/thank_you"
    form.save
    form
  end

  # PREDICATES
  
  def active?
    self.status.downcase == "active" || self.status.downcase == "paused"
  end

  def is_seo?
    self.campaign_style.instance_of?(SeoCampaign)
  end

  def is_sem?
    self.campaign_style.instance_of?(SemCampaign)
  end

  def is_maps?
    self.campaign_style.instance_of?(MapsCampaign)
  end

  def is_basic?
    self.campaign_style.instance_of?(BasicCampaign)
  end
  
  def managed?
    MANAGED_FLAVORS.include?(self.flavor.downcase)
  end
  
  
  # PRIVATE BEHAVIOR

  private

  def remove_from_many_to_many_relationships
    self.industries.each { |industry| industry.campaigns.delete(self) }
  end
  
  def proper_channel?
    unless self.campaign_style.proper_channel?
      errors.add(:channel, "is of the incorrect channel type")
    end
  end

end
