class WebsiteVisit < ActiveRecord::Base
  belongs_to :website
  
  def self.data_pull_websites_visits(hard_update = false, start_date = (Date.today - 8.days), end_date = Date.today - 1.day)
    
    sites = Website.find(:all, :conditions => ['is_active = ? OR is_active is null', 1])
    sites.each do |site|
      begin
       if hard_update == false
         WebsiteVisit.update_website_visits(site.id, start_date, end_date)
       else
         WebsiteVisit.hard_update_visits_individually(site.id, start_date, end_date)
       end
       puts "Updated visits for site: " + site.nickname
      rescue
        puts "Error in updating site: " + site.nickname
        next
      end
    end
  end
  
  def self.update_website_visits(website_id, start = Date.today - 8.days, fend = Date.today - 1.day)
    website = Website.find(website_id)
    if website != nil
      type = 'visitors-list&visitor-details=time,time_pretty,time_total,ip_address,session_id,actions,web_browser,operating_system,screen_resolution,javascript,language,referrer_url,referrer_domain,referrer_search,geolocation,longitude,latitude,hostname,organization,campaign,custom,clicky_url,goals'
      
      time_begin = Time.utc(start.year, start.month, start.day, 0, 0, 0)
      time_end = Time.utc(fend.year, fend.month, fend.day, 23, 59, 59)
      count = ((time_end - time_begin).round)/86400
    
      pull_date = start
      
      while count != 0
        url_dates = pull_date.to_s
        mainurl = "http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=" + website.site_id + "&sitekey=" + website.sitekey + "&date=" + url_dates + "&type=" + type + "&output=json&limit=10000"
        response = HTTParty.get(mainurl).first
        if response["error"] != nil && response["error"] == "Invalid sitekey."
          website.is_active = false
          website.save!
        end 

        if response["dates"] != nil
          begin
            dates = response["dates"].first
            visits = dates["items"]
            visits.each do |visit|
              begin
                nurl = WebsiteVisit.find_or_create_by_session_id_and_website_id(:session_id => visit["session_id"],
                    :website_id => website.id,
                    :actions => visit["actions"],
                    :clicky_url => visit["clicky_url"],
                    :latitude => visit["latitude"],
                    :longitude => visit["longitude"],
                    :language => visit["language"],
                    :screen_resolution => visit["screen_resolution"],
                    :time => visit["time"],
                    :time_pretty => visit["time_pretty"],
                    :time_total => visit["time_total"],
                    :ip_address => visit["ip_address"],
                    :geolocation => visit["geolocation"],
                    :javascript => visit["javascript"],
                    :web_browser => visit["web_browser"],
                    :operating_system => visit["operating_system"],
                    :referrer_url => visit["referrer_url"],
                    :referrer_search => visit["referrer_search"],
                    :hostname => visit["hostname"],
                    :organization => visit["organization"],
                    :campaign => visit["campaign"],
                    :goals => visit["goals"],
                    :custom => visit["custom"])
                  nurl.save
                rescue 
                  puts 'Error in getting' + url_dates
                  next
              end
            end
          rescue
            puts 'No Visits to Record'
          end
          site = Website.find_or_create_by_id(:id => website.id, :is_active => true, :updated_at => Time.now)
          site.save
        else
          site = Website.find_or_create_by_id(:id => website.id, :is_active => false)
          site.save
        end
        pull_date = pull_date + 1.day
        count -= 1
      end
    end
  end
        
  def self.hard_update_website_visits(website_id, start = Date.today - 8.days, fend = Date.today - 1.day)    
    #Eventually make a difference between the two....hard will overwrite data or something
  end
  
end
