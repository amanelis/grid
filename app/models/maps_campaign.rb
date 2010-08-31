class MapsCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_maps_campaigns
  has_many :yahoo_maps_campaigns
  has_many :bing_maps_campaigns
  has_many :map_keywords

  GOOGLE_MAPS_API_KEY = 'ABQIAAAAU2DhWAoQ76ku3zRokt1DnRQX-pfkEHFxdgQJJn1KX_braIcbexTk-gFyApGHhSC0zwacV0-kZeHAzg'
  CHART_COLORS = ["66ccff", "669966", "666666", "cc3366", "ff6633", "ffff33", "000000"]
  
  # INSTANCE BEHAVIOR

  def number_of_visits_by_date
    self.campaign.number_of_map_visits_by_date
  end

  def combined_timeline_data
    raw_data = Utilities.merge_timeline_data(self.number_of_visits_by_date)
    Utilities.massage_timeline(raw_data, [:visits])
  end

  def google_keyword_rankings_graph
    month_date = Date.today
    map_keywords = Array.new
    rankings = Array.new
    citations = Array.new
    user_contents = Array.new
    coupons = Array.new
    reviews = Array.new
    klabels = Array.new

    self.map_keywords.each do |map_keyword|
      rankings << Array.new
    end

    if self.map_keywords != nil
      count = 6
      ranking_count = 0
      counts_count = 0
      while count >= 0
        data_date = month_date - count.months
        data_time_start = Date.new(data_date.year, data_date.month, 1)
        data_time_end = Date.new(data_date.year, data_date.month, data_date::class.civil(data_date.year, data_date.month, -1).day)
        kcount = self.map_keywords.size
        j = 0
        conts = 0
        coups = 0
        revs = 0
        cits = 0
        while j < kcount
          info = MapRanking.find(:all, :conditions => ['local_map_keyword_id = ?  && (ranking_date between ? AND ?)', map_keywords[j].id, data_time_start, data_time_end]).last
          if info != nil
            cits = info.google_citation_count if info.google_citation_count != 0
            conts = info.google_user_content_count if info.google_user_content_count != 0
            coups = info.google_coupon_count if info.google_coupon_count != 0
            revs = info.google_review_count if info.google_review_count != 0
            rank = 0
            rank = info.google_rank if info.google_rank != 1000
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


      days_url = ''
      kcount = self.map_keywords.size
      GoogleChart::LineChart.new('500x150', 'Google Local Map Keyword Rankings', false) do |bc|
        k = 0
        while k < kcount
          bc.data map_keywords[k].keyword, rankings[k], CHART_COLORS[k]
          k += 1
        end
        bc.axis :x, :labels => klabels, :font_size => 10
        bc.axis :y, :range => [0, ranking_count], :font_size => 10
        bc.fill(:background, :solid, {:color => '65432100'})
        bc.fill(:chart, :solid, {:color => '65432100'})
        bc.show_legend = true
        days_url = bc.to_escaped_url
      end
      return days_url
    end
  end
 end
