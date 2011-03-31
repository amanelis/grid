class Website < ActiveRecord::Base
  has_many :campaigns
  has_many :website_visits, :dependent => :destroy

  # CLASS BEHAVIOR

  def self.add_websites
    job_status = JobStatus.create(:name => "Website.add_websites")
    #http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0
    begin
      HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=#{CLICKY_KEY}&output=json")["response"]["site"].each do |url|
        begin
          existing_website = Website.find_by_site_id(url['site_id'])
          if existing_website.blank?
            existing_website = Website.new
            existing_website.site_id = url['site_id']
          end
          existing_website.domain = url["hostname"].downcase
          existing_website.nickname = url["nickname"].downcase
          existing_website.sitekey = url["sitekey"]
          existing_website.database_server = url["server"]
          existing_website.admin_sitekey = url["sitekey_admin"]
          existing_website.is_active = true
          existing_website.save!
        rescue
          next
        end
      end
      sf_campaigns = Salesforce::Clientcampaign.find(:all, :conditions => ['status__c != ? AND status__c != ?', '', 'Inactive'])
      sf_campaigns.each do |sf_campaign|
        begin
          website = Website.find_by_nickname(sf_campaign.primary_website__c.gsub("http://", "")) if sf_campaign.primary_website__c.present?
          if website.present?
            local_campaign = Campaign.find_by_salesforce_id(sf_campaign.id)
            if local_campaign.present?
              local_campaign.website = website
              #website.campaigns << local_campaign unless local_campaign.website.present?   website.campaigns.include?(local_campaign)
              local_campaign.save!
              website.save!
            end
          end
        rescue Exception => ex
          next
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end
  
  def self.fix_salesforce_grid_websites
    Website.all.each do |website|
      website.campaigns.each do |campaign|
        sf_campaign = Salesforce::Clientcampaign.first(:conditions => ['id = ?', campaign.salesforce_id])
        if sf_campaign.present? 
          if sf_campaign.primary_website__c.blank?
            campaign.website = nil
            campaign.save!
          elsif sf_campaign.primary_website__c.gsub("http://", "") != website.nickname
            campaign.website = nil
            campaign.save!
          end
        end
      end
    end
  end
  
  #### GINZA CLASS METHODS
  def self.list_ginza_sites
    HTTParty.get("https://app.ginzametrics.com/v1/list_sites?api_key=#{GINZA_KEY}").to_a
  end
  
  def self.associate_ginza_sites_with_grid_sites
    result = {:updated => 0, :skipped => 0, :errored => 0}
    sites = Website.list_ginza_sites
    if sites.present?
      sites.each do |site| 
        begin
          grid_site = Website.find_by_nickname("www.#{site['site']['domain']}")
          if grid_site.present?
            grid_site.ginza_global_id = site['site']['global_key']
            grid_site.ginza_meta_descript = site['site']['meta_description']
            grid_site.save
            result[:updated] += 1
          else
            result[:skipped] += 1
          end
        rescue
          result[:errored] += 1
          next
        end
      end
    end
    result
  end
  
  # INSTANCE BEHAVIOR

  def visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).count
  end

  def unique_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).count('visitor_id', :distinct => true)
  end

  def map_visits_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.from_maps.between(start_date, end_date).count
  end

  def actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).sum(:actions).to_i
  end
  
  def bounces_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.bounce.between(start_date, end_date).count
  end

  def average_actions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.actions_between(start_date, end_date).to_f / visits : 0.0
  end

  def total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).sum(:time_total).to_i
  end

  def average_total_time_spent_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.total_time_spent_between(start_date, end_date).to_f / visits : 0.0
  end

  def bounces_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).bounce.count
  end

  def bounce_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.bounces_between(start_date, end_date).to_f / visits : 0.0
  end
  
  def unique_contacts_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.campaigns.active.to_a.sum {|campaign| campaign.number_of_unique_calls_between(start_date, end_date) + campaign.number_of_non_spam_submissions_between(start_date, end_date)}
  end
  
  def overall_conversion_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.unique_contacts_between(start_date, end_date).to_f / visits : 0.0
  end
  
  def unique_conversion_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (unique_visits = self.unique_visits_between(start_date, end_date)) > 0 ? self.unique_contacts_between(start_date, end_date).to_f / unique_visits : 0.0
  end
  
  def visitor_visits_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).for_visitor(visitor_id).count
  end

  def visitor_actions_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).for_visitor(visitor_id).sum(:actions).to_i
  end

  def visitor_average_actions_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visitor_visits_between(visitor_id, start_date, end_date)) > 0 ? self.visitor_actions_between(visitor_id, start_date, end_date).to_f / visits : 0.0
  end

  def visitor_total_time_spent_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).for_visitor(visitor_id).sum(:time_total).to_i
  end

  def visitor_average_total_time_spent_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visitor_visits_between(visitor_id, start_date, end_date)) > 0 ? self.visitor_total_time_spent_between(visitor_id, start_date, end_date).to_f / visits : 0.0
  end

  def visitor_bounces_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).for_visitor(visitor_id).bounce.count
  end

  def visitor_bounce_rate_between(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    (visits = self.visitor_visits_between(visitor_id, start_date, end_date)) > 0 ? self.visitor_bounces_between(visitor_id, start_date, end_date).to_f / visits : 0.0
  end
  
  def visits_by_visitor(visitor_id, start_date = Date.yesterday, end_date = Date.yesterday)
    self.website_visits.between(start_date, end_date).for_visitor(visitor_id)
  end

  def first_visit_date_by_visitor(visitor_id)
    visit_date = Date.yesterday
    if self.website_visits.for_visitor(visitor_id).present?
      first_visit = self.website_visits.for_visitor(visitor_id).first.time_of_visit 
      visit_date = Date.new(first_visit.year, first_visit.month, first_visit.day)
    end
  end
  
  def keywords_searched_between(start_date = Date.yesterday, end_date = Date.yesterday)
    search_keywords = Hash.new
    self.website_visits.between(start_date, end_date).referred.each do |visit|
      keywords = visit.referrer_search.downcase.split.join(' ')
      search_keywords[keywords] = (search_keywords.has_key? keywords) ? search_keywords[keywords] + 1 : 1
    end
    search_keywords.sort { |x, y| y[1]<=>x[1] }
  end

  def visit_locations_between(start_date = Date.yesterday, end_date = Date.yesterday)
    visit_locations = Hash.new
    self.website_visits.between(start_date, end_date).each do |visit|
      location = "#{visit.latitude} #{visit.longitude}"
      visit_locations[location] = (visit_locations.has_key? location) ? visit_locations[location] + 1 : 1
    end
    visit_locations.sort { |x, y| y[1]<=>x[1] }
  end

  def number_of_visits_by_date
    self.website_visits.count(:group => "date(time_of_visit)", :order =>"time_of_visit ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:visits => value}; data }
  end

  def number_of_map_visits_by_date
    self.website_visits.from_maps.count(:group => "date(time_of_visit)", :order =>"time_of_visit ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:visits => value}; data }
  end

  def get_traffic_sources(start_date = (Date.today - 30), end_date = Date.today)
    HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=#{self.site_id}&sitekey=#{self.sitekey}&type=traffic-sources&date=#{start_date.to_s},#{end_date.to_s}&output=json&limit=10000").first["dates"].first["items"]
  end

  def visitors_by_location_graph(start_date = Date.today - 30.days, end_date = Date.yesterday, height = 300, width = 500, zoom = 8)
    map_url = ''
    visits = self.website_visits.find(:all, :conditions => ['time_of_visit between ? AND ?', start_date.beginning_of_day, end_date.end_of_day])
    if self.campaigns.first.zip_code.present? && visits.present?
      markers = Array.new()
      visits.each do |visit|
        check = markers.detect { |x| x[0] == visit.latitude.to_f and x[1] == visit.longitude.to_f }
        if check == nil
          markers.push(Hash["lat" => visit.latitude.to_f, "long" => visit.longitude.to_f, "count" => 1])
        else
          check["count"] += 1
        end
      end
      if markers.present?
        #Get Geocode from Zip Code
        response = HTTParty.get("http://local.yahooapis.com/MapsService/V1/geocode?appid=YD-9G7bey8_JXxQP6rxl.fBFGgCdNjoDMACQA--&zip=#{self.campaigns.first.zip_code.to_s}")
        map = StaticGmaps::Map.new :center => [sprintf("%.3f", response['ResultSet']['Result']['Latitude'].to_f).to_f, sprintf("%.3f", response['ResultSet']['Result']['Longitude'].to_f).to_f], :zoom => zoom, :size => [width, height], :map_type => :roadmap, :key => GOOGLE_MAPS_API_KEY
        map.markers.clear
        markers[0..49].each do |marker|
          map.markers << StaticGmaps::Marker.new(:latitude => sprintf("%.3f", marker["lat"]).to_f, :longitude => sprintf("%.3f", marker["long"]).to_f, :color => :blue)
        end
        map_url = URI.escape(map.url + "&format=png")
      end
    end
    return map_url
  end
  
  #### GINZA INSTANCE METHODS
  def get_ginza_site_keyword_count
    begin
      HTTParty.get("https://app.ginzametrics.com/v1/sites/#{self.ginza_global_id}/active_keywords?api_key=#{GINZA_KEY}").parsed_response
    rescue Exception => ex
      raise
    end
  end
  
  def get_ginza_latest_rankings
    begin
      HTTParty.get("https://app.ginzametrics.com/v1/sites/#{self.ginza_global_id}/latest_rankings?api_key=#{GINZA_KEY}&count=100").to_a
    rescue Exception => ex
      raise
    end
  end
  
  def get_ginza_latest_ranking_date
    begin
      response = HTTParty.get("https://app.ginzametrics.com/v1/sites/#{self.ginza_global_id}/latest_rankings_date?api_key=#{GINZA_KEY}").to_a.first
      if response != "Quota exceeded"
        dates = response.split('-')
        ranking_date = Date.new(dates[0].to_i, dates[1].to_i, dates[2].to_i)
      end
    rescue Exception => ex
      raise
    end
  end
  
  def create_clicky_site
    url = "https://api.getclicky.com/api/account/sites?username=cityvoicesa&password=C1tyv01c3&output=json"
    site_id = sitekey = database_server = admin_sitekey = ''
    successfuly_found_or_added = false
    
    HTTParty.get(url).each do |site|
      site_id = site["site_id"] 
      sitekey = site["sitekey"]
      database_server = ''
      admin_sitekey = site["sitekey_admin"]
      successfuly_found_or_added = true
    end
    
    if successfuly_found_or_added
      self.is_active = true
      self.site_id = site_id
      self.sitekey = sitekey
      self.database_server = database_server
      self.admin_sitekey = admin_sitekey
      self.save!
      return "Website was created!\nClick Code: <script src=\"http://stats.cityvoice.com/js\" type=\"text/javascript\"></script><script type=\"text/javascript\">citystats.init(#{site_id});</script><noscript><p><img alt=\"CityStats\" width=\"1\" height=\"1\" src=\"http://stats.cityvoice.com/#{site_id}ns.gif\" /></p></noscript>"
    end
    
  end
  
  #TESTING GINZA METHODS
  
  def create_ginza_site
    if self.ginza_global_id.blank?
      response = HTTParty.get("https://app.ginzametrics.com/v1/accounts/#{GINZA_ACCOUNT_ID}/add_site?api_key=#{GINZA_KEY}&format=json&url=#{self.nickname}&market=US")
      if response.to_a.first.first == "site"
        self.ginza_global_id = response.to_a.first.second["global_key"]
        self.ginza_meta_descript = response.to_a.first.second["meta_description"]
        self.save
        return true
      else
        return response.to_a.first
      end
    end
  end
end

