class MapKeyword < ActiveRecord::Base
  belongs_to :maps_campaign
  has_many :map_rankings, :dependent => :destroy


  # CLASS BEHAVIOR

  def self.update_keywords_from_salesforce
    job_status = JobStatus.create(:name => "MapKeyword.update_keywords_from_salesforce")
    begin
      sf_campaigns = Salesforce::Clientcampaign.find_all_by_campaign_type__c('Local Maps')
      sf_campaigns.each do |sf_campaign|
        local_map_campaign = Campaign.find_by_salesforce_id(sf_campaign.id).try(:campaign_style)
        if sf_campaign.keywords__c.present? && local_map_campaign.present?
          keywords = sf_campaign.keywords__c.gsub(', ', ',')
          keywords = keywords.split(',')
          keywords.each do |keyword|
            puts 'Started: ' + keyword
            MapKeyword.find_or_create_by_maps_campaign_id_and_descriptor(:maps_campaign_id => local_map_campaign.id,
                                                                         :descriptor => keyword,
                                                                         :ranking_updated_on => nil)
            puts 'Completed: ' + keyword
          end
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end

  def self.update_map_rankings
    job_status = JobStatus.create(:name => "MapKeyword.update_map_rankings")
    begin
      MapKeyword.all.each { |map_keyword| map_keyword.fetch_map_rankings }
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
  end


  # INSTANCE BEHAVIOR

  def fetch_map_rankings
    if self.ranking_updated_on.blank? || self.ranking_updated_on < Date.today - 6.days
      google_result = self.get_google_ranking
      yahoo_result = self.get_yahoo_ranking
      bing_result = self.get_bing_ranking
      self.map_rankings.create(:ranking_date => Date.today,
                               :google_rank => google_result[0],
                               :yahoo_rank => yahoo_result[0],
                               :bing_rank => bing_result[0],
                               :google_coupon_count => google_result[1],
                               :google_review_count => google_result[2],
                               :google_citation_count => google_result[3],
                               :google_user_content_count => google_result[4],
                               :google_places_ranking => google_result[5],
                               :google_insiderpages_review_count => google_result[6],
                               :google_customerlobby_review_count => google_result[7],
                               :google_citysearch_review_count => google_result[8],
                               :google_judysbook_review_count => google_result[9],
                               :google_yahoo_review_count => google_result[10],
                               :google_insiderpages_rating => google_result[11],
                               :google_customerlobby_rating => google_result[12],
                               :google_citysearch_rating => google_result[13],
                               :google_judysbook_rating => google_result[14],
                               :google_yahoo_rating => google_result[15],
                               :bing_review_count => bing_result[2],
                               :yahoo_review_count => yahoo_result[5],
                               :yahoo_review_rating => yahoo_result[8],
                               :yahoo_last_review_date => yahoo_result[10])
      google_campaign = self.maps_campaign.google_maps_campaigns.first
      if google_campaign.present?
        #Update Data here
      else
        self.maps_campaign.google_maps_campaigns.build()
      end
      yahoo_campaign = self.maps_campaign.yahoo_maps_campaigns.first
      if yahoo_campaign.present?
        yahoo_campaign.maps_url = yahoo_result[4]
        yahoo_campaign.reference_id = yahoo_result[6]
        yahoo_campaign.save!
      else
        self.maps_campaign.yahoo_maps_campaigns.build(:maps_url => yahoo_result[4],
                                                      :reference_id => yahoo_result[6])
      end
      bing_campaign = self.maps_campaign.bing_maps_campaigns.first
      if bing_campaign.present?
        bing_campaign.reference_id = bing_result[3]
        bing_campaign.maps_url = bing_result[1]
        bing_campaign.save!
      else
        self.maps_campaign.bing_maps_campaigns.build(:maps_url => bing_result[1],
                                                     :reference_id => bing_result[3])
      end
      self.ranking_updated_on = Date.today
      self.save!
    end
  end

  #Returns result = { "result" => 1000, "company_name" => "NA", "address" => "NA", "phone" => "NA", "page" => "NA", "review_count" => 0, "coupon_count" => 0, "citation_count" => 0, "user_content_count" => 0, google_places_ranking, google_insiderpages_review_count

  def get_google_ranking
    begin
      search_keyword = self.descriptor.gsub(" ", "+")
      start_page = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
      google_url = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
      page_num = 0
      result = 1000
      company_name = 'NA'
      address = 'NA'
      phone = 'NA'
      page = 'NA'
      review_count = 0
      coupon_count = 0
      citation_count = 0
      user_content_count = 0
      google_places_ranking = 0
      google_insiderpages_review_count = 0
      google_customerlobby_review_count = 0
      google_citysearch_review_count = 0
      google_judysbook_review_count = 0
      google_yahoo_review_count = 0
      google_insiderpages_rating = 0
      google_customerlobby_rating = 0
      google_citysearch_rating = 0
      google_judysbook_rating = 0
      google_yahoo_rating = 0
      company = self.maps_campaign.company_name.present? ? self.maps_campaign.company_name : self.campaign.account.name
      place_url = 'NA'

      #If not in the 7 Pack....find the ranking!
      if result == 1000
        20.times do
          source = HTTParty.get(google_url)
          begin
            results_start = source.index("text vcard indent block")
            results_stop = source.index("pw res")
            results = source[results_start..results_stop]
            results = results.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
            if results.include? company
              whole_page = results.split("text vcard indent block")
              whole_page.delete_at(0)
              whole_page.each do |result_item|
                result_item_block = result_item.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
                if result_item_block.include? company
                  page_start = result_item.index("href=\"/maps")
                  page_stop = result_item.index("&q")
                  if page_start.present? && page_stop.present?
                    page = result_item[page_start..page_stop]
                    page = "http://maps.google.com" + page[6..(page.length - 2)]
                    result = page_num + (whole_page.index(result_item) + 1)
                    break
                  end
                end
              end
            else
              page_num += 10
              google_url = start_page + "&start=" + page_num.to_s()
            end
          rescue
          end
          break if result != 1000
        end
      end

      if page != 'NA'
        page_source = HTTParty.get(page)
        page_source = page_source.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
        owner_start = page_source.index('From the owner')
        if page_source.present? and owner_start.present?
          other_source = page_source[0..owner_start]
          page_source = page_source[owner_start..page_source.length]

          #Get Places Rating
          
          rating_start = page_source.index('g:rating_override')
          rating_end = page_source.index('rsw-stars')
          if rating_start.present? && rating_end.present?
            google_places_ranking = page_source[(rating_start + 19)..(rating_end - 10)]
          end
          #Get Company Name
          company_start = page_source.index("pp-place-title")
          company_block = page_source[company_start..page_source.length]
          company_stop = company_block.index("</span>")
          company_name = company_block[22..(company_stop - 1)]

          #Get Address
          address = "None"
          address_start = company_block.index("pp-headline-address")
          address_big_block = company_block[address_start..company_block.length]
          address_stop = address_big_block.index("</span>")
          if address_start.present? && address_stop.present?
            address_block = address_big_block[0..address_stop]
            address = address_block[27..(address_block.length - 2)]
          end
          address = address

          #Get Phone
          phone = "NA"
          phone_start = company_block.index("<nobr>")
          phone_stop = company_block.index("</nobr>")
          if phone_start.present? || phone_stop.present?
            phone = company_block[(phone_start + 6)..(phone_stop - 1)]
          end
          phone = phone

          #Get Number of reviews
          review = 0
          if company_block.include? 'More reviews by Google users'
            review_start = company_block.index('More reviews by Google users')
            review_block = company_block[review_start..company_block.length]
            review_stop = review_block.index(')')
            if review_stop.present?
              final_block = review_block[43..(review_stop - 8)]
              review = 2 + final_block.to_i
            end
          else
            review_start = company_block.index("Reviews by Google users")
            review_stop = company_block.index('Related places')
            if review_start.present? && review_stop.present?
              review_block = company_block[review_start..review_stop]
              reviews = review_block.split('pp-story-item')
              reviews.delete_at(0)
              review = reviews.size
            end
          end
          review_count = review.to_i if review.present?

          #Get Number of coupons
          coupons = 0
          if company_block.include? 'More offers'
            coupon_start = company_block.index('More offers')
            coupon_block = company_block[coupon_start..company_block.length]
            coupon_stop = coupon_block.index(')')
            if coupon_stop.present?
              final_block = coupon_block[13..(coupon_stop - 1)]
              coupons = 3 + final_block.to_i
            end
          else
            coupon_start = company_block.index("Offers")
            coupon_stop = company_block.index('Reviews')
            if coupon_start.present? || coupon_stop.present?
              coupon_block = company_block[coupon_start..coupon_stop]
              num_coupons = coupon_block.split('pp-coupons-img')
              num_coupons.delete_at(0)
              coupons = num_coupons.size
            end
          end
          coupon_count = coupons.to_i if coupons.present?

          #Get Citations
          citations = 0
          citation_start = company_block.index("More about this place")
          if citation_start.present?
            first_block = company_block[citation_start..company_block.length]
            citation_stop = first_block.index('pp-footer-links pp-footer-line')
            citation_stop = first_block.index('pp-footer') if !citation_stop.present?
            citation_block = first_block[0..citation_stop] if citation_stop.present?
            if citation_block.present?
              if citation_block.include? '>More'
                count_start = citation_block.index('>More (')
                count_stop = citation_block.index(') &raquo;')
                if count_start.present? && count_stop.present?
                  citations = 5 + citation_block[(count_start + 7)..(count_stop - 1)].to_i
                end
              else
                citation_count = citation_block.split('pp-attribution')
                citations = citation_count.size - 1
              end
            end
          end
          citation_count = citations.to_i if citations.present?

          #Get User Content
          user_content = 0
          content_start = other_source.index("Related Maps")
          if content_start.present?
            first_block = other_source[content_start..(other_source.length - 1)]
            user_content = (first_block.split('ugc-attribution').count - 1).to_i
          end
          user_content_count = user_content.to_i if user_content.present?
        end
        
        review_page = page + '&view=feature&mcsrc=provider_blocks&num=10&start=0&ved=0COABELUF&sa=X&ei=rU35TN-oKJOwywW_irGMBA'
        review_source = HTTParty.get(review_page)
        review_source = review_source.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
        #Get InsiderPages Info
        insider_start = review_source.index('<span>insiderpages.com</span>')
        if insider_start.present?
          insider_block = review_source[insider_start..(review_source.length - 1)]
          insider_stop = (insider_block.index('</span> reviews') - 1) if insider_block.present?
          google_insiderpages_review_count = insider_block[38..insider_stop].to_i if insider_stop.present?
          
          insider_star_end = insider_block.index('webreview')
          insider_star_block = insider_block[0..insider_star_end]
          google_insiderpages_rating = (insider_star_block.split('rsw-starred').count - 1)
        end
        
        #Get CustomerLobby Info
        lobby_start = review_source.index('<span>customerlobby.com</span>')
        if lobby_start.present?
          lobby_block = review_source[lobby_start..(review_source.length - 1)]
          lobby_stop = (lobby_block.index('</span> reviews') - 1)
          google_customerlobby_review_count = lobby_block[39..lobby_stop].to_i
          
          lobby_star_end = lobby_block.index('webreview')
          lobby_star_block = lobby_block[0..lobby_star_end]
          google_customerlobby_rating = (lobby_star_block.split('rsw-starred').count - 1)
        end
        
        #Get CitySearch Info
        citysearch_start = review_source.index('citysearch.com</span>')
        if citysearch_start.present?
          citysearch_block = review_source[citysearch_start..(review_source.length - 1)]
          citysearch_stop = (citysearch_block.index('</span> reviews') - 1)
          google_citysearch_review_count = citysearch_block[30..citysearch_stop].to_i
          
          citysearch_star_end = citysearch_block.index('webreview')
          citysearch_star_block = citysearch_block[0..citysearch_star_end]
          google_citysearch_rating = (citysearch_star_block.split('rsw-starred').count - 1)
        end
        
        #Get Yahoo Info yahoo.com - 3 reviews
        yahoo_start = review_source.index('yahoo.com</span>')
        if yahoo_start.present?
          yahoo_block = review_source[yahoo_start..(review_source.length - 1)]
          yahoo_stop = (yahoo_block.index('</span> reviews') - 1)
          google_yahoo_review_count = yahoo_block[25..yahoo_stop].to_i
          
          yahoo_star_end = yahoo_block.index('webreview')
          yahoo_star_block = yahoo_block[0..yahoo_star_end]
          google_yahoo_rating = (yahoo_star_block.split('rsw-starred').count - 1)
        end
        
        #Get Judysbook Info yahoo.com - 3 reviews
        judysbook_start = review_source.index('judysbook.com</span>')
        if judysbook_start.present?
          judysbook_block = review_source[judysbook_start..(review_source.length - 1)]
          judysbook_stop = (judysbook_block.index('</span> reviews') - 1)
          google_judysbook_review_count = judysbook_block[29..judysbook_stop].to_i
          
          judysbook_star_end = judysbook_block.index('webreview')
          judysbook_star_block = judysbook_block[0..judysbook_star_end]
          google_judysbook_rating = (judysbook_star_block.split('rsw-starred').count - 1)
        end
        
      end
    rescue Exception => e
      puts "#{ e } : #{ e.backtrace }"
      return [result, coupon_count, review_count, citation_count, user_content_count, google_places_ranking, google_insiderpages_review_count, google_customerlobby_review_count, google_citysearch_review_count, google_judysbook_review_count, google_yahoo_review_count, google_insiderpages_rating, google_customerlobby_rating, google_citysearch_rating, google_judysbook_rating, google_yahoo_rating]
    end
    return [result, coupon_count, review_count, citation_count, user_content_count, google_places_ranking, google_insiderpages_review_count, google_customerlobby_review_count, google_citysearch_review_count, google_judysbook_review_count, google_yahoo_review_count, google_insiderpages_rating, google_customerlobby_rating, google_citysearch_rating, google_judysbook_rating, google_yahoo_rating]
  end

  def get_yahoo_ranking
    search_keyword = self.descriptor
    search_city = ''
    cities_string = self.maps_campaign.campaign.target_cities.gsub(', ', ',') if self.maps_campaign.campaign.target_cities.present?
    cities = ''
    cities = cities_string.split(',') if cities_string.present?
    cities.each do |city|
      if search_keyword.include? city
        search_city = city
        search_keyword.gsub(city, '')
      end
    end
    search_keyword = search_keyword.gsub('+', '')
    company = self.maps_campaign.company_name.present? ? self.maps_campaign.company_name : self.campaign.account.name
    result = 1000
    company_name = 'NA'
    address = 'NA'
    phone = 'NA'
    map_url = 'NA'
    review_count = 0
    yahoo_id = 'NA'
    categories = 'NA'
    rating = 0
    website_url = 'NA'
    last_review_date = 'NA'
    state = 'NA'
    start_num = 0
    url = 'http://local.yahooapis.com/LocalSearchService/V3/localSearch?appid=V.aHUKPV34F4PgtK3n9.LE_zy6gaNTOXc.g2J2Bd10mi8FtXI7CjzfbgwsZNDIMQp4Y4&query=' + search_keyword.gsub(' ', '+') + '&location=' + search_city.gsub(' ', '+') + '&output=json&results=20&start='
    begin
      while start_num < 232
        response_url = url + start_num.to_s
        response = HTTParty.get(response_url)['ResultSet']['Result']
        index = response.find_index { |i| i['Title'] == company }
        if index.present?
          result = index + start_num
          company_name = response[index]['Title']
          address = response[index]['Address']
          phone = response[index]['Phone']
          map_url = response[index]['Url']
          review_count = response[index]['Rating']['TotalReviews']
          yahoo_id = response[index]['id']
          cats_string = ''
          cats = response[index]['Categories']['Category']
          cats.each do |category|
            cats_string = cats_string + (category['content'] + ', ')
          end
          cats_string = cats_string[0..cats_string.length - 3]
          categories = cats_string
          rating = response[index]['Rating']['AverageRating']
          website_url = response[index]['BusinessUrl']
          last_review_date = response[index]['LastReviewDate']
          state = response[index]['State']
          start_num = 250
        else
          start_num += 20
        end
      end
    rescue
      return [result, company_name, address, phone, map_url, review_count, yahoo_id, categories, rating, website_url, last_review_date, state]
    end
    return [result, company_name, address, phone, map_url, review_count, yahoo_id, categories, rating, website_url, last_review_date, state]
  end


  def get_bing_ranking
    search_keyword = self.descriptor.gsub(" ", "+")
    company = self.maps_campaign.company_name.present? ? self.maps_campaign.company_name : self.campaign.account.name
    result = 1000
    map_url = 'NA'
    review_count = 0
    bing_id = 'NA'
    start_num = 0
    url = 'http://www.bing.com/local/Default.aspx?q=' + search_keyword.gsub(' ', '+') + '&start='
    begin
      while start_num < 250
        response_url = url + start_num.to_s
        response = HTTParty.get(response_url)
        if response.include? company
          items = response.split('{Title:')

          url_items = items[(items.size - 10)..(items.size - 1)]
          index = url_items.find_index { |i| i.include? company }
          result = index + start_num + 1
          url_start = url_items[index].index('Url:') + 5
          url_end = url_items[index].index('Logging') - 3
          map_url = MapKeyword.decode_msn_bullshit(url_items[index][url_start..url_end].downcase)

          if map_url.present?
            id_start = map_url.index('lid=') + 4
            id_stop = map_url.index('&q=') - 1
            bing_id = map_url[id_start..id_stop]
            site_response = HTTParty.get(map_url)
            review_start = site_response.index('onReviewLinkClick')
            review_block = site_response[review_start..site_response.length - 1]
            if review_block.present?
              review_block_start = review_block.index('Reviews (')
              review_block_end = review_block.index('</a>')
              if review_block_start.present? && review_block_end.present?
                review_count = review_block[review_block_start + 9..review_block_end - 2].to_i
              end
            end
          end
          start_num = 250
        else
          start_num += 10
        end
      end
      return [result, map_url, review_count, bing_id]
    rescue
      return [result, map_url, review_count, bing_id]
    end
  end

  def self.decode_msn_bullshit(url)
    return url.gsub('\\x3a', ':').gsub('\\x2f', '/').gsub('\\x3f', '?').gsub('\\x3d', '=').gsub('\\x26', '&').gsub('\\x2520', '+')
  end
  
  def most_recent_google_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:google_rank)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end

  def most_recent_yahoo_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:yahoo_rank)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end

  def most_recent_bing_ranking
    ((ranking = ((first_rank = self.most_recent_ranking.try(:bing_rank)).present?) ? first_rank : 101) > 100) ? 101 : ranking
  end
  
  def google_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.map_rankings.between(start_date, end_date)).present? ? ([rankings.first.google_rank, 100].compact.min) - ([rankings.last.google_rank, 100].compact.min) : 0
  end

  def yahoo_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.map_rankings.between(start_date, end_date)).present? ? ([rankings.first.yahoo_rank, 100].compact.min) - ([rankings.last.yahoo_rank, 100].compact.min) : 0
  end

  def bing_ranking_change_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (rankings = self.map_rankings.between(start_date, end_date)).present? ? ([rankings.first.bing_rank, 100].compact.min) - ([rankings.last.bing_rank, 100].compact.min) : 0
  end
  
  def most_recent_google_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:google_rank)).present? ? ranking : 0
  end

  def most_recent_yahoo_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:yahoo_rank)).present? ? ranking : 0
  end

  def most_recent_bing_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    (ranking = self.most_recent_ranking_between(start_date, end_date).try(:bing_rank)).present? ? ranking : 0
  end
  
  
  def most_recent_ranking()
    self.map_rankings.last
  end
  
  def most_recent_ranking_between(start_date = Date.today - 30.day, end_date = Date.yesterday)
    self.map_rankings.between(start_date, end_date).try(:last)
  end

end
