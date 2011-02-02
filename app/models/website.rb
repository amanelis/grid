class Website < ActiveRecord::Base
  has_many :campaigns
  has_many :website_visits, :dependent => :destroy

  GOOGLE_MAPS_API_KEY = 'ABQIAAAALQRqYHHjSnLmL7zwbG0n-BQkiq2IPuxpcd6yKI6maifg0dbT5RQMwn92qd1fSdzERnpNoeonkmJ_Cw'
  
  GINZA_KEY = '32cb93caac0403cdaad7e0683ad10cf2'
  GINZA_USERNAME = 'kate.wright'
  GINZA_PASSWORD = 'cityvoice'

  # CLASS BEHAVIOR

  def self.add_websites
    job_status = JobStatus.create(:name => "Website.add_websites")
    #http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0
    begin
      geturl = HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0&output=json")
      response = geturl["response"]
      urls = response["site"]
      urls.each do |url|
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
      end

      sf_campaigns = Salesforce::Clientcampaign.all
      sf_campaigns.each do |sf_campaign|
        website = Website.find_by_nickname(sf_campaign.primary_website__c)
        if website.present?
          local_campaign = Campaign.find_by_salesforce_id(sf_campaign.id)
          if local_campaign.present?
            local_campaign.website = website
            #website.campaigns << local_campaign unless local_campaign.website.present?   website.campaigns.include?(local_campaign)
            local_campaign.save!
            website.save!
          end
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
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
      location = visit.latitude + ' ' + visit.longitude
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
    begin
      type = 'traffic-sources'
      #mainurl = "http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=185568&sitekey=27ca05a49f331f13&type=visitors-list&visitor-details=time,time_pretty,time_total,ip_address,session_id,actions,web_browser,operating_system,screen_resolution,javascript,language,referrer_url,referrer_domain,referrer_search,geolocation,longitude,latitude,hostname,organization,campaign,custom,clicky_url,goals&date=2010-04-01,2010-04-30&source=advertising&domain=google.com"
      mainurl = "http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=" + self.site_id + "&sitekey=" + self.sitekey + "&type=" + type + "&date=" + start_date.to_s + "," + end_date.to_s + "&output=json&limit=10000"
      response = HTTParty.get(mainurl).first
      dateblock = response["dates"]
      itemblock = dateblock.first
      items = itemblock["items"]
      return items
    rescue
      return nil
    end
  end

  def visitors_by_location_graph(start_date = Date.today - 30.days, end_date = Date.yesterday, height = 300, width = 500, zoom = 8)
    start_date_time = start_date.beginning_of_day
    end_date_time = end_date.end_of_day
    map_url = ''
    visits = self.website_visits.find(:all, :conditions => ['time_of_visit between ? AND ?', start_date_time, end_date_time])
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
        url = 'http://local.yahooapis.com/MapsService/V1/geocode?appid=YD-9G7bey8_JXxQP6rxl.fBFGgCdNjoDMACQA--&zip=' + self.campaigns.first.zip_code.to_s
        response = HTTParty.get(url)
        long = sprintf("%.3f", response['ResultSet']['Result']['Longitude'].to_f).to_f
        lat = sprintf("%.3f", response['ResultSet']['Result']['Latitude'].to_f).to_f
        map = StaticGmaps::Map.new :center => [lat, long], :zoom => zoom, :size => [width, height], :map_type => :roadmap, :key => GOOGLE_MAPS_API_KEY
        map.markers.clear
        markers[0..49].each do |marker|
          map.markers << StaticGmaps::Marker.new(:latitude => sprintf("%.3f", marker["lat"]).to_f, :longitude => sprintf("%.3f", marker["long"]).to_f, :color => :blue)
        end
        map_url = URI.escape(map.url + "&format=png")
      end
    end
    return map_url
  end
  
  
  
  #### NEEDS TO BE SET AS AN CLASS VARIABLE ON WEBSITE---IN TESTING PHASE
  def self.list_ginza_sites
    begin
      HTTParty.get("https://app.ginzametrics.com/v1/list_sites?api_key=#{GINZA_KEY}").to_a
    rescue Exception => ex
      raise
    end
  end
  
  #### NEEDS TO BE SET AS AN INSTANCE VARIABLE ON WEBSITE---IN TESTING PHASE
  def self.get_ginza_site_keyword_count(global_id = '9e082ec734be')
    begin
      HTTParty.get("https://app.ginzametrics.com/v1/sites/#{global_id}/active_keywords?api_key=#{GINZA_KEY}").parsed_response
    rescue Exception => ex
      raise
    end
  end
  
  #### NEEDS TO BE SET AS AN INSTANCE VARIABLE ON WEBSITE---IN TESTING PHASE
  def self.get_ginza_latest_rankings(global_id = '9e082ec734be')
    begin
      HTTParty.get("https://app.ginzametrics.com/v1/sites/#{global_id}/latest_rankings?api_key=#{GINZA_KEY}").to_a
    rescue Exception => ex
      raise
    end
  end
  
  
  #### NEEDS TO BE SET AS AN INSTANCE VARIABLE ON WEBSITE---IN TESTING PHASE
  def self.get_ginza_latest_ranking_date(global_id = '9e082ec734be')
    begin
      dates = HTTParty.get("https://app.ginzametrics.com/v1/sites/#{global_id}/latest_rankings_date?api_key=#{GINZA_KEY}").to_a.first.split('-')
      ranking_date = Date.new(dates[0].to_i, dates[1].to_i, dates[2].to_i) unless dates[0] == "Quota exceeded"
    rescue Exception => ex
      raise
    end
  end
  
  def self.associate_ginza_sites_with_grid_sites()
    result = {:updated => 0, :skipped => 0, :errored => 0}
    sites = Website.list_ginza_sites
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
    result
  end
  
  
  
end

