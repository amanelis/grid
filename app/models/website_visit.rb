class WebsiteVisit < ActiveRecord::Base
  belongs_to :website

  named_scope :bounce, :conditions => ['actions = ? AND time_total <= ?', 1, 15]
  named_scope :referred, :conditions => ['referrer_search IS NOT NULL']
  named_scope :from_google_maps, :conditions => ['referrer_url like ?', '%maps.google.com%']
  named_scope :from_yahoo_maps, :conditions => ['referrer_url like ?', '%local.yahoo.com%']
  named_scope :from_bing_maps, :conditions => ['referrer_url like ?', '%bing.com/local%']
  named_scope :from_maps, :conditions => ['referrer_url like ? OR referrer_url like ? OR referrer_url like ?', '%maps.google.com%', '%local.yahoo.com%', '%bing.com/local%']
  named_scope :between, lambda { |start_date, end_date| {:conditions => ['time_of_visit between ? AND ?', start_date.to_time_in_current_zone.at_beginning_of_day.utc, end_date.to_time_in_current_zone.end_of_day.utc], :order => 'time_of_visit ASC'} }
  named_scope :for_date, lambda { |date| {:conditions => ['time_of_visit between ? AND ?', date.to_time_in_current_zone.at_beginning_of_day.utc, date.to_time_in_current_zone.end_of_day.utc]} }
  named_scope :for_visitor, lambda { |visitor| {:conditions => ['visitor_id = ?', visitor]} }


  # CLASS BEHAVIOR

  def self.data_pull_websites_visits(hard_update = false, start_date = (Date.today - 2.days), end_date = Date.yesterday, verbose = false)
    job_status = JobStatus.create(:name => "WebsiteVisit.data_pull_websites_visits")
    exception = nil
    sites = Website.find(:all, :conditions => ['is_active = ? OR is_active is null', 1])
    sites.each do |site|
      begin
        if hard_update == false
          exception = WebsiteVisit.update_website_visits(site.id, start_date, end_date, verbose)
        else
          exception = WebsiteVisit.hard_update_website_visits(site.id, start_date, end_date)
        end
        puts "Updated visits for site: " + site.nickname
      rescue Exception => ex
        puts "Error in updating site: " + site.nickname
        exception = ex
        next
      end
    end
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
    Account.cache_results_for_accounts
  end

  def self.update_website_visits(website_id, start = Date.today - 2.days, fend = Date.yesterday, verbose = false)
    exception = nil
    website = Website.find(website_id)
    if website.present?
      type = 'visitors-list&visitor-details'

      time_begin = start.to_time.utc.at_beginning_of_day
      time_end = fend.to_time.utc.end_of_day
      count = ((time_end - time_begin).round)/86400

      pull_date = start

      while count != 0
        url_dates = pull_date.to_s
        mainurl = "http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=" + website.site_id + "&sitekey=" + website.sitekey + "&date=" + url_dates + "&type=" + type + "&output=json&limit=10000"
        response = HTTParty.get(mainurl).first
        if response["error"].present? && response["error"] == "Invalid sitekey."
          website.is_active = false
          website.save!
        else
          if response["dates"].present?
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
                                                                                :custom => visit["custom"],
                                                                                :landing_page => visit["landing_page"],
                                                                                :referrer_type => visit["referrer_type"],
                                                                                :visitor_id => visit["uid"],
                                                                                :time_of_visit => Time.at(visit["time"].to_i))
                puts "Saved visit from #{nurl.geolocation}" if verbose
              rescue Exception => ex
                exception = ex
                next
              end
            end
          end
        end
        pull_date += 1.day
        count -= 1
      end
    end
    exception
  end

  def self.hard_update_website_visits(website_id, start = Date.today - 2.days, fend = Date.yesterday)
    exception = nil
    website = Website.find(website_id)
    if website.present?
      type = 'visitors-list&visitor-details'

      time_begin = start.to_time.utc.at_beginning_of_day
      time_end = fend.to_time.utc.end_of_day
      count = ((time_end - time_begin).round)/86400

      pull_date = start

      while count != 0
        url_dates = pull_date.to_s
        mainurl = "http://stats.cityvoice.com.re.getclicky.com/api/stats/4?site_id=" + website.site_id + "&sitekey=" + website.sitekey + "&date=" + url_dates + "&type=" + type + "&output=json&limit=10000"
        response = HTTParty.get(mainurl).first
        if response["error"].present? && response["error"] == "Invalid sitekey."
          website.is_active = false
          website.save!
        else
          if response["dates"].present?
            dates = response["dates"].first
            visits = dates["items"]
            visits.each do |visit|
              begin
                nurl = WebsiteVisit.find_by_session_id_and_website_id(visit["session_id"], website.id)
                if nurl.present?
                  nurl.actions = visit["actions"]
                  nurl.clicky_url = visit["clicky_url"]
                  nurl.latitude = visit["latitude"]
                  nurl.longitude = visit["longitude"]
                  nurl.language = visit["language"]
                  nurl.screen_resolution = visit["screen_resolution"]
                  nurl.time = visit["time"]
                  nurl.time_pretty = visit["time_pretty"]
                  nurl.time_total = visit["time_total"]
                  nurl.ip_address = visit["ip_address"]
                  nurl.geolocation = visit["geolocation"]
                  nurl.javascript = visit["javascript"]
                  nurl.web_browser = visit["web_browser"]
                  nurl.operating_system = visit["operating_system"]
                  nurl.referrer_url = visit["referrer_url"]
                  nurl.referrer_search = visit["referrer_search"]
                  nurl.hostname = visit["hostname"]
                  nurl.organization = visit["organization"]
                  nurl.campaign = visit["campaign"]
                  nurl.goals = visit["goals"]
                  nurl.custom = visit["custom"]
                  nurl.landing_page = visit["landing_page"]
                  nurl.referrer_type = visit["referrer_type"]
                  nurl.visitor_id = visit["uid"]
                  nurl.time_of_visit = Time.at(visit["time"].to_i)
                  nurl.save!
                else
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
                                                                                :custom => visit["custom"],
                                                                                :landing_page => visit["landing_page"],
                                                                                :referrer_type => visit["referrer_type"],
                                                                                :visitor_id => visit["uid"],
                                                                                :time_of_visit => Time.at(visit["time"].to_i))
                end
              rescue Exception => ex
                exception = ex
                next
              end
            end
          end
        end
        pull_date += 1.day
        count -= 1
      end
    end
    exception
  end


  # INSTANCE BEHAVIOR
  
  def all_visits_from_visitor()
    self.class.find_all_by_visitor_id(self.visitor_id)
  end
  
  def possible_calls(time_span = 2)
    return [] if time_span.blank?
    self.website.campaigns.inject([]) { |possible_calls, campaign| possible_calls << campaign.calls.snapshot(self.time_of_visit, time_span) }.flatten.sort {|a,b| a.call_start <=> b.call_start }
  end
  
  def possible_submissions(time_span = 2)
    return [] if time_span.blank?
    self.website.campaigns.inject([]) { |possible_submissions, campaign| possible_submissions << campaign.submissions.snapshot(self.time_of_visit, time_span) }.flatten.sort {|a,b| a.time_of_submission <=> b.time_of_submission }
  end
  
end
