class SeoCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :keywords, :dependent => :destroy
  has_many :inbound_links, :dependent => :destroy
  has_many :website_analyses, :class_name => "WebsiteAnalysis", :dependent => :destroy


  # CLASS BEHAVIOR

  def self.update_websites_with_ginza
    job_status = JobStatus.create(:name => "SeoCampaign.update_websites_with_ginza")
    begin
      Website.associate_ginza_sites_with_grid_sites
      (Campaign.seo.select {|camp| camp.website.present? && camp.website.ginza_global_id.blank? && camp.status != "Inactive"}).each do |campaign|
        puts "Checking #{campaign.name}"
        if campaign.website.create_ginza_site
          puts "Added #{campaign.website.nickname} to Ginza" #if campaign.website.create_ginza_site
        else
          puts "#{campaign.website.nickname} was not added to Ginza"
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end
  
  def self.update_website_keywords_with_ginza
    test_status = "Began Running"
    job_status = JobStatus.create(:name => "SeoCampaign.update_website_keywords_with_ginza")
    begin
      #Make sure sites are current
      (Campaign.seo.select {|camp| camp.website.present? && camp.website.ginza_global_id.present? && camp.status != "Inactive"}).each do |campaign|
        campaign.website.update_attribute(:last_keyword_update, Date.yesterday) if campaign.website.present? && campaign.website.last_keyword_update.blank?
        #Change Date.today when we get past 240 websites or Ginza takes off the 10 queries/hr shit.
        if campaign.website.present? && campaign.website.ginza_global_id.present?
          campaign.campaign_style.add_ginza_keywords
          if campaign.website.last_keyword_update != Date.today
            rankings = campaign.website.get_ginza_latest_rankings
            if rankings != ["Quota exceeded"] && rankings.present?
              campaign.website.get_ginza_latest_rankings.each do |g_keyword|
                keyword = campaign.campaign_style.keywords.find_by_descriptor(g_keyword['keyword']['name'])
                if keyword.blank?
                  #create the keyword
                  keyword = campaign.campaign_style.keywords.build
                  keyword.descriptor = g_keyword['keyword']['name']
                end
                keyword.ginza_keyword_id = g_keyword['keyword']['keyword_id']
                keyword.google_first_page = (g_keyword['keyword']['google_us'].to_i < 11)
                keyword.yahoo_first_page = (g_keyword['keyword']['yahoo_us'].to_i < 11)
                #keyword.bing_first_page = (g_keyword['keyword']['bing_us'].to_i < 11) ? true : false
                keyword.bing_first_page = false
                keyword.last_ranking_update = Date.today
                keyword.save!
                  
                #create a ranking for the keyword
                ranking = keyword.keyword_rankings.build
                ranking.google = (g_keyword['keyword']['google_us'].to_i < 100) ? g_keyword['keyword']['google_us'].to_i : 99999
                ranking.yahoo = (g_keyword['keyword']['yahoo_us'].to_i  < 100) ? g_keyword['keyword']['yahoo_us'].to_i : 99999
                #ranking.bing = (g_keyword['keyword']['bing_us'].to_i  < 100) ? g_keyword['keyword']['bing_us'].to_i : 99999
                ranking.bing = 99999
                ranking.ginza_conv_percent = g_keyword['keyword']['conversion_percent'].to_f
                ranking.ginza_visits = g_keyword['keyword']['visits'].to_i 
                ranking.ginza_conversions = g_keyword['keyword']['conversions'].to_i 
                ranking.date_of_ranking = Date.today
                ranking.save!
                test_status = "Ran through all of the websites" 
              end
              puts "#{campaign.website.nickname} was Updated"
              campaign.website.update_attribute(:last_keyword_update, Date.today)
            else
              test_status = "Reached Query Limit" if rankings != ["Quota exceeded"]
            end
          end
        end
        if campaign.website.present?
          puts "#{campaign.website.nickname} was Previously Updated" if campaign.website.ginza_global_id.present? && campaign.website.last_keyword_update != Date.today
        end
      end  
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
    test_status
  end


  # INSTANCE BEHAVIOR

  def add_ginza_keywords(keywords = "")
    return unless self.campaign.website.present? && self.campaign.website.ginza_global_id.present?
    keywords_not_yet_in_ginza = self.keywords.reject {|keyword| keyword.in_ginza?}
    return unless keywords_not_yet_in_ginza.present?
    keywords_not_yet_in_ginza.each do |keyword|
      response = (HTTParty.get("https://app.ginzametrics.com/v1/sites/#{self.campaign.website.ginza_global_id}/add_keywords", :query => {:api_key => GINZA_KEY, :format => 'json', :keywords => keyword.descriptor})).to_a.first
      keyword.update_attribute(:in_ginza, true) if response.include? "Keywords added"
    end
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

  def website_traffic_sources_graph(start_date = Date.today - 1.month, end_date = Date.today, height = 250, width = 900)
    width = 900 if width > 900
    height = 300 if height > 300
    website = self.website
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

  def seo_keyword_rankings_graph(height = 250, width = 900)
    width = 900 if width > 900
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

  
  # PREDICATES
  
  def proper_channel?
    self.channel.blank? || self.channel.is_seo?
  end
  
end
