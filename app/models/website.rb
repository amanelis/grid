class Website < ActiveRecord::Base
  has_and_belongs_to_many :campaigns, :uniq => true
  has_many :website_visits


  # CLASS BEHAVIOR

  def self.add_websites
    #http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0
    geturl = HTTParty.get("http://stats.cityvoice.com.re.getclicky.com/api/whitelabel/sites?auth=de8f1bae61c60eb0&output=json")
    response = geturl["response"]
    urls = response["site"]
    urls.each do |url|
      Website.find_or_create_by_site_id(:site_id => url["site_id"],
                                        :domain => url["hostname"].downcase,
                                        :nickname => url["nickname"].downcase,
                                        :sitekey => url["sitekey"],
                                        :database_server => url["server"],
                                        :admin_sitekey => url["sitekey_admin"],
                                        :is_active => true)
    end

    sf_campaigns = Salesforce::Clientcampaign.all
    sf_campaigns.each do |sf_campaign|
      website = Website.find_by_nickname(sf_campaign.primary_website__c)
      if website.present?
        local_campaign = Campaign.find_by_name(sf_campaign.name)
        if local_campaign.present?
          website.campaigns << local_campaign  unless website.campaigns.include?(local_campaign)
          website.save
        end
      end
    end
  end


  # INSTANCE BEHAVIOR

  def visits_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.website_visits.between(start_date, end_date).count
  end

  def actions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.website_visits.between(start_date, end_date).sum(:actions).to_i
  end

  def average_actions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.actions_between(start_date, end_date).to_f / visits : 0.0
  end

  def total_time_spent_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.website_visits.between(start_date, end_date).sum(:time_total).to_i
  end

  def average_total_time_spent_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.total_time_spent_between(start_date, end_date).to_f / visits : 0.0
  end

  def bounces_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.website_visits.between(start_date, end_date).bounce.count
  end

  def bounce_rate_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (visits = self.visits_between(start_date, end_date)) > 0 ? self.bounces_between(start_date, end_date).to_f / visits : 0.0
  end

  def keywords_searched_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    search_keywords = Hash.new
    self.website_visits.between(start_date, end_date).referred.each do |visit|
      keywords = visit.referrer_search.downcase.split.join(' ')
      search_keywords[keywords] = (search_keywords.has_key? keywords) ? search_keywords[keywords] + 1 : 1
    end
    search_keywords.sort { |x, y| y[1]<=>x[1] }
  end

  def visit_locations_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    visit_locations = Hash.new
    self.website_visits.between(start_date, end_date).each do |visit|
      location = visit.latitude + ' ' + visit.longitude
      visit_locations[location] = (visit_locations.has_key? location) ? visit_locations[location] + 1 : 1
    end
    visit_locations.sort { |x, y| y[1]<=>x[1] }
  end

  def number_of_visits_by_date
    self.website_visits.count(:group => "date(time_of_visit)", :order =>"time_of_visit ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:visit => value} ; data}
  end

  def number_of_map_visits_by_date
    self.website_visits.from_maps.count(:group => "date(time_of_visit)", :order =>"time_of_visit ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:visit => value} ; data}
  end

end

