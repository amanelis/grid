class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords, :dependent => :destroy
  has_many :inbound_links, :dependent => :destroy
  has_many :website_analyses, :class_name => "WebsiteAnalysis", :dependent => :destroy

  #GOOGLE_MAPS_API_KEY = 'ABQIAAAAU2DhWAoQ76ku3zRokt1DnRQX-pfkEHFxdgQJJn1KX_braIcbexTk-gFyApGHhSC0zwacV0-kZeHAzg'
  GOOGLE_MAPS_API_KEY = 'ABQIAAAAzr2EBOXUKnm_jVnk0OJI7xSosDVG8KKPE1-m51RBrvYughuyMxQ-i1QfUnH94QxWIa6N4U6MouMmBA'
  CHART_COLORS = ["66ccff", "669966", "666666", "cc3366", "ff6633", "ffff33", "000000"]


  # CLASS BEHAVIOR

  def self.update_inbound_links
    job_status = JobStatus.create(:name => "SeoCampaign.update_inbound_links")
    exception = nil
    begin
      seo_campaigns = SeoCampaign.all
      seo_campaigns.each do |seo_campaign|
        websites = seo_campaign.websites
        if websites.present?
          websites.each do |website|
            begin
              freshness = seo_campaign.inbound_links.find(:all, :conditions => ['created_at > ?', 1.day.ago])
              if freshness.empty? && website.nickname.present?
                url = 'http://perl.pearanalytics.com/v2/domain/get/linklist?url=http://' + website.nickname.gsub('http://', '')
                response = HTTParty.get(url)
                links = JSON.parse(response)['result']
                if links.present?
                  links.each do |link|
                    begin
                      existing_link = InboundLink.find_by_link_url_and_seo_campaign_id(link, seo_campaign.id)
                      if existing_link.present?
                        existing_link.last_date_found = Date.today
                        existing_link.save
                      else
                        InboundLink.create(:link_url => link, :seo_campaign_id => seo_campaign.id, :last_date_found => Date.today, :is_active => true)
                      end
                    rescue Exception => ex
                      exception = ex
                      next
                    end
                  end
                end
              end
            rescue Exception => ex
              exception = ex
              next
            end
          end
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
  end

  def self.clean_up_inbound_links
    job_status = JobStatus.create(:name => "SeoCampaign.clean_up_inbound_links")
    begin
      links = InboundLink.all
      links.each do |link|
        if link.last_date_found < (Date.today - 60.days)
          link.is_active = false
          link.save!
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

  def self.update_website_analyses
    job_status = JobStatus.create(:name => "SeoCampaign.update_website_analyses")
    begin
      seo_campaigns = SeoCampaign.all
      seo_campaigns.each do |seo_campaign|
        websites = seo_campaign.websites
        if websites.present?
          websites.each do |website|
            freshness = seo_campaign.website_analyses.find(:all, :conditions => ['created_at > ?', 1.day.ago])
            if freshness.empty? && website.nickname.present?
              pearscore = seo_campaign.getpearscore(website.nickname)
              google_pagerank = seo_campaign.getgooglepagerank(website.nickname)
              alexa_rank = seo_campaign.getalexarank(website.nickname)
              sitewide_inbound_link_count = seo_campaign.get_sitewide_inbound_link_count(website.nickname)
              page_specific_inbound_link_count = seo_campaign.get_page_specific_inbound_link_count(website.nickname)
              WebsiteAnalysis.create(:seo_campaign_id => seo_campaign.id, :pear_score => pearscore, :google_pagerank => google_pagerank, :alexa_rank => alexa_rank, :sitewide_inbound_link_count => sitewide_inbound_link_count, :page_specific_inbound_link_count => page_specific_inbound_link_count)
            end
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

  def getpearscore(nickname)
    begin
      url = build_pear_url("linkanalysis/getpearscore", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["pear_score"]
    rescue
      puts "Error in Account.getpearscore"
      return nil
    end
  end

  def getgooglepagerank(nickname)
    begin
      url = build_pear_url("linkanalysis/getgooglepagerank", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["google_pagerank"]
    rescue
      puts "Error in Account.getgooglepagerank"
      return nil
    end
  end

  def get_new_google_page_rank(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/rank/google?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.getgooglepagerank"
      return nil
    end
  end

  def getalexarank(nickname)
    begin
      url = build_pear_url("linkanalysis/getalexarank", {"url" => nickname, "format" => "json"})
      response = HTTParty.get(url)
      response["alexa_rank"]
    rescue
      puts "Error in Account.getalexarank"
      return nil
    end
  end

  def get_new_alexa_rank(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/rank/alexa?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_alexa_rank"
      return nil
    end
  end

  def get_page_specific_inbound_link_count(nickname)
    begin
      url = build_pear_url("linkanalysis/getinboundlinkcount", {"url" => nickname, "format" => "json", "page_specific" => "1"})
      response = HTTParty.get(url)
      response["inbound_link_count"]
    rescue
      puts "Error in Account.get_page_specific_inbound_link_count"
      return nil
    end
  end

  def get_sitewide_inbound_link_count(nickname)
    begin
      url = build_pear_url("linkanalysis/getinboundlinkcount", {"url" => nickname, "format" => "json", "page_specific" => "0"})
      response = HTTParty.get(url)
      response["inbound_link_count"]
    rescue
      puts "Error in Account.get_sitewide_inbound_link_count"
      return nil
    end
  end

  def get_new_sitewide_inbound_link_count(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/get/links?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_sitewide_inbound_link_count"
      return nil
    end
  end

  def get_new_html_validation_errors(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/valid/html?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']['errors']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_load_time(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/page/loadtime?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']['time']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_site_map_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/sitemap?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_robots_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/robots?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def get_new_404_response_status(nickname)
    begin
      url = 'http://perl.pearanalytics.com/v2/domain/has/404-response?url=http://' + nickname.gsub('http://', '')
      response = HTTParty.get(url)
      JSON.parse(response)['result']
    rescue
      puts "Error in Account.get_new_html_validation"
      return nil
    end
  end

  def build_pear_url(uri, parameters, api_key = "819f9b322610b816c898899ddad715a2e76fc3c5", api_secret = "2c312c9626b79d2fa47321753a18a2672e4d58aa")
    parameters["signature"] = self.calculate_pear_signature(uri, parameters, api_secret)
    parameters["api_key"] = api_key
    pieces = []
    parameters.each { |key, value| pieces << CGI.escape(key) + '=' + CGI.escape(value) }
    "http://juice.pearanalytics.com/api.php/" + uri + '?' + pieces.join('&')
  end

  def calculate_pear_signature(uri, parameters, api_secret)
    parameters = parameters.sort()
    signature = uri.to_s() + ':' + api_secret.to_s() + '%'
    parameters.each { |key, value| signature += key.to_s() + '=' + value.to_s() + ';' }
    Digest::SHA1.hexdigest(signature)
  end

  def spend_between(start_date = Date.today - 1.month, end_date = Date.today)
    (budget = self.budget).present? ? budget * (end_date - start_date).to_i / 30.0 : 0.0
  end

  def cost_between(start_date = Date.today - 1.month, end_date = Date.today)
    (budget = self.budget).present? ? budget * (end_date - start_date).to_i / 30.0 : 0.0
  end

  def number_of_visits_by_date
    self.campaign.number_of_visits_by_date
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

  def combined_timeline_data
    raw_data = Utilities.merge_timeline_data(self.number_of_visits_by_date, self.number_of_leads_by_date)
    Utilities.massage_timeline(raw_data, [:visits, :leads])
  end

  def website_traffic_sources_graph(start_date = Date.today - 1.month, end_date = Date.today, height = 250, width = 750)
   width = 1000 if width > 1000
      height = 300 if height > 300
      website = self.websites.first
      source_url = ''
      if website != nil
        items = website.get_traffic_sources(start_date, end_date)
        if items != nil
          titles = Array.new()
          values = Array.new()
          labels = Array.new()
          items.each do |item|
            begin
            titles.push(item["title"])
            values.push(item["value"].to_i)
            labels.push(item["value_percent"] + "% (" + item["value"] + ")")
            rescue
              next
            end
          end
          chart_size = width.to_s + 'x' + height.to_s
          GoogleChart::PieChart.new(chart_size, "Web Traffic Sources", true) do |pc|
            i = 0
            (0..(titles.size - 1)).each do |t|
              pc.data titles[i], values[i], CHART_COLORS[i]
              i += 1
            end
            pc.show_legend = true
            pc.show_labels = false
            pc.axis :x, :labels => labels, :font_size => 10
            pc.fill(:background, :solid, {:color => '65432100'})
            pc.fill(:chart, :solid, {:color => '65432100'})
            source_url = pc.to_escaped_url
          end
        end
      end
      return source_url
  end

  def seo_keyword_rankings_graph(height = 250, width = 1000)
    width = 1000 if width > 1000
    height = 300 if height > 300
    days_url = ''
    google_array = Array.new
    yahoo_array = Array.new
    bing_array = Array.new
    keyword_array = Array.new
    keyword_labels = Array.new
    keywords = self.keywords
    count = 11
    while count >= 0
      data_date = Date.today - count.months
      data_time_start = Date.new(data_date.year, data_date.month, 1)
      data_time_end = Date.new(data_date.year, data_date.month, data_date::class.civil(data_date.year, data_date.month, -1).day)
      google_count = 0
      bing_count = 0
      yahoo_count = 0
      keywords.each do |keyword|
        ranking = keyword.keyword_rankings.last(:conditions => ['created_at between ? AND ?', data_time_start, data_time_end])
        if ranking.present?
          google_count += 1 if ranking.google.present? && ranking.google < 11
          yahoo_count += 1 if ranking.yahoo.present? && ranking.yahoo < 11
          bing_count += 1 if ranking.bing.present? && ranking.bing < 11
        end
      end
      google_array.push(google_count)
      yahoo_array.push(yahoo_count)
      bing_array.push(bing_count)
      keyword_array.push(keywords.count)
      keyword_labels.push((data_date.month.to_s + '/' + data_date.year.to_s[2..3]))

      count -= 1
    end

    if keywords.count != 0
      chart_name = "1st Page Spots out of " + keywords.count.to_s + " Keywords"
      chart_size = width.to_s + 'x' + height.to_s
      GoogleChart::LineChart.new(chart_size, chart_name, false) do |bc|
        bc.data "", keyword_array, '65432100'
        bc.data "Google" + ' (' + google_array.last.to_s + ')', google_array, CHART_COLORS[0]
        bc.data "Yahoo" + ' (' + yahoo_array.last.to_s + ')', yahoo_array, CHART_COLORS[1]
        bc.data "Bing" + ' (' + bing_array.last.to_s + ')', bing_array, CHART_COLORS[2]
        bc.axis :x, :labels => keyword_labels, :font_size => 10
        bc.axis :y, :range => [0, keywords.count], :font_size => 10
        bc.fill(:background, :solid, {:color => '65432100'})
        bc.fill(:chart, :solid, {:color => '65432100'})
        bc.show_legend = true
        days_url = bc.to_escaped_url
      end
    end
    return days_url
  end

  def seo_keyword_ranking_table(start_date = Date.today - 1.month, end_date = Date.today)
    keyword_table = Array.new

    keywords = self.keywords
    this_start_date = start_date.beginning_of_day
    this_end_date = end_date.end_of_day
    last_start_date = (start_date - 1.month).beginning_of_day
    last_end_date = (end_date - 1.month).end_of_day

    keywords.each do |keyword|
      this_google_rank = 99999
      last_google_rank = 99999
      this_yahoo_rank = 99999
      last_yahoo_rank = 99999
      this_bing_rank = 99999
      last_bing_rank = 99999

      this_ranking = keyword.keyword_rankings.last(:conditions => ['created_at between ? AND ?', this_start_date, this_end_date])
      if this_ranking.present?
        this_google_rank = this_ranking.google if this_ranking.google.present?
        this_yahoo_rank = this_ranking.yahoo if this_ranking.yahoo.present?
        this_bing_rank = this_ranking.bing if this_ranking.bing.present?
      end
      last_ranking = keyword.keyword_rankings.last(:conditions => ['created_at between ? AND ?', last_start_date, last_end_date])
      if last_ranking.present?
        last_google_rank = last_ranking.google if last_ranking.google.present?
        last_yahoo_rank = last_ranking.yahoo if last_ranking.yahoo.present?
        last_bing_rank = last_ranking.bing if last_ranking.bing.present?
      end
      this_google_rank = 51 if this_google_rank > 50
      last_google_rank = 51 if last_google_rank > 50
      this_yahoo_rank = 51 if this_yahoo_rank > 50
      last_yahoo_rank = 51 if last_yahoo_rank > 50
      this_bing_rank = 51 if this_bing_rank > 50
      last_bing_rank = 51 if last_bing_rank > 50
      this_google_rank = 1 if this_google_rank == 0
      last_google_rank = 1 if last_google_rank == 0
      this_yahoo_rank = 1 if this_yahoo_rank == 0
      last_yahoo_rank = 1 if last_yahoo_rank == 0
      this_bing_rank = 1 if this_bing_rank == 0
      last_bing_rank = 1 if last_bing_rank == 0
      google_change = last_google_rank - this_google_rank
      yahoo_change = last_yahoo_rank - this_yahoo_rank
      bing_change = last_bing_rank - this_bing_rank
      keyword_table.push([keyword.descriptor, this_google_rank, google_change, this_yahoo_rank, yahoo_change, this_bing_rank, bing_change])
    end
    keyword_table = keyword_table.sort { |x, y| x[1] <=> y[1] }

    keyword_table.each_index do |index|
      keyword_table[index][2] = '+' + keyword_table[index][2].to_s if keyword_table[index][2] > 0
      keyword_table[index][4] = '+' + keyword_table[index][4].to_s if keyword_table[index][4] > 0
      keyword_table[index][6] = '+' + keyword_table[index][6].to_s if keyword_table[index][6] > 0
      keyword_table[index][1] = '> 50' if keyword_table[index][1] > 50
      keyword_table[index][3] = '> 50' if keyword_table[index][3] > 50
      keyword_table[index][5] = '> 50' if keyword_table[index][5] > 50
    end
    return keyword_table
  end

  def seo_keyword_ranking_date(start_date = Date.today - 1.year, end_date = Date.today)
    keywords = self.keywords
    this_start_date = start_date.beginning_of_day
    this_end_date = end_date.end_of_day
    keywords.each do |keyword|
      this_ranking = keyword.keyword_rankings.last(:conditions => ['created_at between ? AND ?', this_start_date, this_end_date])
      if this_ranking.present?
        ranking_date = this_ranking.create_at
        return ranking_date
      end
    end
  end

end
