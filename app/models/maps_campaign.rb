class MapsCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_maps_campaigns, :dependent => :destroy
  has_many :yahoo_maps_campaigns, :dependent => :destroy
  has_many :bing_maps_campaigns, :dependent => :destroy
  has_many :map_keywords, :dependent => :destroy

  
  # INITIALIZATION
  
  def initialize_thyself
    self.campaign.initialize_thyself
    self.keywords ||= ""
    self.company_name ||= ""
    self.street ||= ""
    self.city ||= ""
    self.county ||= ""
    self.state ||= ""
    self.postal_code ||= ""
    self.country ||= ""
  end
  

  # INSTANCE BEHAVIOR

  def number_of_visits_by_date
    self.campaign.number_of_map_visits_by_date
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

  def combined_timeline_data
    raw_data = Utilities.merge_timeline_data(self.number_of_visits_by_date)
    Utilities.massage_timeline(raw_data, [:visits])
  end

  def google_keyword_rankings_graph(height = 150, width = 900)
    height = 300 if height > 300
    width = 900 if width > 900
    month_date = Date.today
    map_keywords = Array.new
    rankings = Array.new
    klabels = Array.new

    self.map_keywords.each do |map_keyword|
      rankings << Array.new
    end

    if self.map_keywords != nil
      count = 6
      ranking_count = 0
      while count >= 0
        data_date = month_date - count.months
        data_time_start = Date.new(data_date.year, data_date.month, 1)
        data_time_end = Date.new(data_date.year, data_date.month, data_date::class.civil(data_date.year, data_date.month, -1).day)
        kcount = self.map_keywords.count
        j = 0
        while j < kcount
          info = self.map_keywords[j].map_rankings.find(:all, :conditions => ['ranking_date between ? AND ?', data_time_start, data_time_end])
          if info.last != nil
            rank = 0
            rank = info.last.google_rank if info.last.google_rank != 1000
            rankings[j].push(rank)
            ranking_count = rank if rank > ranking_count
          else
            rank = 0
            rankings[j].push(rank)
            ranking_count = rank if rank > ranking_count
          end
          j += 1
        end
        klabels.push((data_date.month.to_s + '/' + data_date.year.to_s[2..3]))
        count -= 1
      end
      rankings.each do |ranking|
        ranking.each_index { |index| ranking[index] = (ranking_count - ranking[index]) if ranking[index] != 0 }
      end

      days_url = ''
      kcount = self.map_keywords.count
      if kcount != 0
        chart_size = width.to_s + 'x' + height.to_s
        GoogleChart::LineChart.new(chart_size, 'Google Local Map Keyword Rankings', false) do |bc|
          k = 0
          while k < kcount
            bc.data self.map_keywords[k].descriptor + ' (' + (ranking_count - rankings[k].last).to_s + ')', rankings[k], CHART_COLORS[k]
            k += 1
          end
          bc.axis :x, :labels => klabels, :font_size => 10
          bc.axis :y, :range => [(ranking_count + 1), 1], :font_size => 10
          bc.fill(:background, :solid, {:color => '65432100'})
          bc.fill(:chart, :solid, {:color => '65432100'})
          bc.show_legend = true
          days_url = bc.to_escaped_url
        end
      end
      return days_url

    end
  end

  def google_map_data_counts_graph(height = 150, width = 900)
    height = 300 if height > 300
    width = 900 if width > 900
    month_date = Date.today
    rankings = Array.new
    citations = Array.new
    user_contents = Array.new
    coupons = Array.new
    reviews = Array.new
    klabels = Array.new

    self.map_keywords.each do |map_keyword|
      rankings << Array.new
    end
    counts_count = 0
    if self.map_keywords != nil
      count = 6
      while count >= 0
        data_date = month_date - count.months
        data_time_start = Date.new(data_date.year, data_date.month, 1)
        data_time_end = Date.new(data_date.year, data_date.month, data_date::class.civil(data_date.year, data_date.month, -1).day)
        kcount = self.map_keywords.count
        j = 0
        conts = 0
        coups = 0
        revs = 0
        cits = 0
        while j < kcount
          info = self.map_keywords[j].map_rankings.find(:all, :conditions => ['ranking_date between ? AND ?', data_time_start, data_time_end])
          if info.last != nil
            cits = info.last.google_citation_count if info.last.google_citation_count != 0
            conts = info.last.google_user_content_count if info.last.google_user_content_count != 0
            coups = info.last.google_coupon_count if info.last.google_coupon_count != 0
            revs = info.last.google_review_count if info.last.google_review_count != 0
          end
          j += 1
        end
        klabels.push((data_date.month.to_s + '/' + data_date.year.to_s[2..3]))
        reviews.push(revs)
        citations.push(cits)
        user_contents.push(conts)
        coupons.push(coups)
        counts_count = revs if revs > counts_count
        counts_count = cits if cits > counts_count
        counts_count = conts if conts > counts_count
        counts_count = coups if coups > counts_count
        count -= 1
      end
    end
    data_url = ''
    chart_size = width.to_s + 'x' + height.to_s
    GoogleChart::LineChart.new(chart_size, 'Google Local Map Data Counts', false) do |bc|
      bc.data 'Reviews' + ' (' + reviews.last.to_s + ')', reviews, CHART_COLORS[0]
      bc.data 'Citations' + ' (' + citations.last.to_s + ')', citations, CHART_COLORS[1]
      bc.data 'User Content' + ' (' + user_contents.last.to_s + ')', user_contents, CHART_COLORS[2]
      bc.data 'Coupons' + ' (' + coupons.last.to_s + ')', coupons, CHART_COLORS[3]
      bc.axis :x, :labels => klabels, :font_size => 10
      bc.axis :y, :range => [0, counts_count], :font_size => 10
      bc.fill(:background, :solid, {:color => '65432100'})
      bc.fill(:chart, :solid, {:color => '65432100'})
      bc.show_legend = true
      data_url = bc.to_escaped_url
    end
    return data_url
  end

  def google_map_website_clicks_graph(height = 150, width = 900)
    height = 300 if height > 300
    width = 900 if width > 900
    month_date = Date.today
    slabels = Array.new
    searches = Array.new
    search_max = 0
    m = 11
    while m > 0
      data_date = month_date - m.months
      data_time_start = Date.new(data_date.year, data_date.month, 1)
      data_time_end = Date.new(data_date.year, data_date.month, data_date::class.civil(data_date.year, data_date.month, -1).day)

      if visits = self.website.try(:map_visits_between, data_time_start, data_time_end)
        searches.push(visits)
        search_max = visits if visits > search_max
      else
        searches.push(0)
      end
      slabels.push((data_time_start.month.to_s + '/' + data_time_start.year.to_s[2..3]))
      m -= 1
    end
    search_url = ''
    chart_size = width.to_s + 'x' + height.to_s

    GoogleChart::LineChart.new(chart_size, 'Google Local Map Website Clicks', false) do |bc|
      bc.data 'Clicks on Website', searches, CHART_COLORS[0]
      bc.axis :x, :labels => slabels, :font_size => 10
      bc.axis :y, :range => [0, search_max], :font_size => 10
      bc.fill(:background, :solid, {:color => '65432100'})
      bc.fill(:chart, :solid, {:color => '65432100'})
      bc.show_legend = false
      search_url = bc.to_escaped_url
    end
    return search_url
  end
  
  
  # PREDICATES
  
  def valid_channel?
    true
  end
  
end
