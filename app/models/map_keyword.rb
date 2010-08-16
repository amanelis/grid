class MapKeyword < ActiveRecord::Base
  belongs_to :maps_campaign
  has_many :map_rankings


  def self.update_keywords_from_salesforce
    sf_campaigns = Salesforce::Clientcampaign.find_all_by_campaign_type__c('Local Maps')
    sf_campaigns.each do |sf_campaign|
      local_map_campaign = Campaign.find_by_name(sf_campaign.name).try(:campaign_style)
      if sf_campaign.keywords__c.present? && local_map_campaign.present?
        keywords = sf_campaign.keywords__c.split(',')
        keywords.each do |keyword|
          puts 'Started: ' + keyword
          MapKeyword.find_or_create_by_maps_campaign_id_and_descriptor(:maps_campaign_id => local_map_campaign.id,
                                                                       :descriptor => keyword,
                                                                       :ranking_updated_on => nil)
          puts 'Completed: ' + keyword
        end
      end
    end
  end

  def self.update_map_rankings
    MapKeyword.all.each { |map_keyword| map_keyword.fetch_map_rankings }
  end

  def fetch_map_rankings
    if self.ranking_updated_on.blank? || self.ranking_updated_on < Date.today - 6.days
      google_result = self.get_google_ranking
      yahoo_result = self.get_yahoo_ranking
      bing_result = self.get_bing_ranking
      if google_result.present?
        self.map_rankings.create(:ranking_date => Date.today,
                                 :google_rank => google_result['result'],
                                 :yahoo_rank => yahoo_result,
                                 :bing_rank => bing_result,
                                 :google_coupon_count => google_result['coupon_count'],
                                 :google_review_count => google_result['review_count'],
                                 :google_citation_count => google_result['citation_count'],
                                 :google_user_content_count => google_result['user_content_count'])
        self.ranking_updated_on = Date.today
        self.save!
      end
    end
  end

  #Returns result = { "result" => 1000, "company_name" => "NA", "address" => "NA", "phone" => "NA", "page" => "NA", "review_count" => 0, "coupon_count" => 0, "citation_count" => 0, "user_content_count" => 0 }
  def get_google_ranking
    begin
      search_keyword = self.descriptor.gsub(" ", "+")
      start_page = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
      google_url = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
      page_num = 0
      result = {"result" => 1000, "company_name" => "NA", "address" => "NA", "phone" => "NA", "page" => "NA", "review_count" => 0, "coupon_count" => 0, "citation_count" => 0, "user_content_count" => 0}
      company = self.maps_campaign.company_name.present? ? self.maps_campaign.company_name : self.campaign.account.name
      place_url = 'NA'

      #Check the 7 pack first
      pack_check_url = 'http://www.google.com/search?q=' + search_keyword
      pack_source = HTTParty.get(pack_check_url)
      if pack_source.present?
        pack_start = pack_source.index("Local business results")
        pack_stop = pack_source.index("More results near")
        pack_block = pack_source[pack_start..pack_stop]
        pack_block = pack_block.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
        if pack_block.include? company
          pack_items = pack_block.split('<tr>')
          pack_items.slice!(0..1)
          pack_count = 1
          pack_items.each do |pack_item|
            pack_item_block = pack_item.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
            if pack_item_block.include? company
              result['result'] = pack_count
              place_start = pack_item.index('class=fl')
              place_block = pack_item[place_start..(pack_item.length - 1)]
              place_end = place_block.index("&ei")
              block = place_block[16..(place_end - 1)]
              cid = block.index('cid')
              mapsid = block[cid..block.length]
              result['page'] = 'http://maps.google.com/maps/place?' + mapsid
              break
            end
            pack_count += 1
          end
        end
      end

      #If not in the 7 Pack....find the ranking!
      if result["result"] == 1000
        20.times do
          source = HTTParty.get(google_url)
          results_start = source.index("id=title")
          results_stop = source.index("pw res")
          results = source[results_start..results_stop]
          results = results.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
          if results.include? company
            whole_page = results.split("id=title")
            whole_page.delete_at(0)
            whole_page.each do |result_item|
              result_item_block = result_item.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
              if result_item_block.include? company
                page_start = result_item.index("href=/maps")
                page_stop = result_item.index("&q")
                if page_start.present? && page_stop.present?
                  page = result_item[page_start..page_stop]
                  result['page'] = "http://maps.google.com" + page[5..(page.length - 2)]
                  result['result'] = page_num + (whole_page.index(result_item) + 1)
                  break
                end
              end
            end
          else
            page_num += 10
            google_url = start_page + "&start=" + page_num.to_s()
          end
          break if result['result'] != 1000
        end
      end

      if result['page'] != 'NA'
        page_source = HTTParty.get(result['page'])
        page_source = page_source.gsub("<b>", "").gsub("</b>", "").gsub("&amp;", "&").gsub("&#39;", "'")
        owner_start = page_source.index('From the owner')
        page_source = page_source[owner_start..page_source.length]

        #Get Company Name
        company_start = page_source.index("place-title>")
        company_block = page_source[company_start..page_source.length]
        company_stop = company_block.index("</span>")
        result["company_name"] = company_block[12..(company_stop - 1)]

        #Get Address
        address = "None"
        address_start = company_block.index("address")
        address_big_block = company_block[address_start..company_block.length]
        address_stop = address_big_block.index("</span>")
        if address_start.present? && address_stop.present?
          address_block = address_big_block[0..address_stop]
          address = address_block[9..(address_block.length - 2)]
        end
        result["address"] = address

        #Get Phone
        phone = "NA"
        phone_start = company_block.index("<nobr>")
        phone_stop = company_block.index("</nobr>")
        if phone_start.present? || phone_stop.present?
          phone = company_block[(phone_start + 6)..(phone_stop - 1)]
        end
        result["phone"] = phone

        #Get Number of reviews
        review = 0
        if company_block.include? 'More reviews'
          review_start = company_block.index('More reviews')
          review_block = company_block[review_start..company_block.length]
          review_stop = review_block.index(')')
          if review_stop.present?
            final_block = review_block[14..(review_stop - 1)]
            review = 5 + final_block.to_i
          end
        else
          review_start = company_block.index("pp-story-item")
          review_stop = company_block.index('Nearby places you might like')
          if review_start.present? && review_stop.present?
            review_block = company_block[review_start..review_stop]
            reviews = review_block.split('pp-story-item')
            reviews.delete_at(0)
            review = reviews.size
          end
        end
        result["review_count"] = review.to_i if review.present?

        #Get Number of coupons
        coupons = 0
        if company_block.include? 'More coupons'
          coupon_start = company_block.index('More coupons')
          coupon_block = company_block[coupon_start..company_block.length]
          coupon_stop = coupon_block.index(')')
          if coupon_stop.present?
            final_block = coupon_block[14..(coupon_stop - 1)]
            coupons = 3 + final_block.to_i
          end
        else
          coupon_start = company_block.index("pp-coupons-img>")
          coupon_stop = company_block.index('>Reviews<')
          if coupon_start.present? || coupon_stop.present?
            coupon_block = company_block[coupon_start..coupon_stop]
            num_coupons = coupon_block.split('pp-coupons-img>')
            num_coupons.delete_at(0)
            coupons = num_coupons.size
          end
        end
        result["coupon_count"] = coupons.to_i if coupons.present?

        #Get Citations
        citations = 0
        citation_start = company_block.index("More about this place")
        if citation_start.present?
          first_block = company_block[citation_start..company_block.length]
          citation_stop = first_block.index('class=pp-story-bar')
          citation_block = first_block[0..citation_stop] if citation_stop.present?
          if citation_block.present?
            if citation_block.include? '>More'
              count_start = citation_block.index('>More (')
              count_stop = citation_block.index(') &raquo;')
              if count_start.present? && count_stop.present?
                citations = 5 + citation_block[(count_start + 7)..(count_stop - 1)].to_i
              end
            end
          else
            citation_count = citation_block.split('pp-attribution>')
            citations = citation_count.size - 1
          end
        end
        result["citation_count"] = citations.to_i if citations.present?

        #Get User Content
        user_content = 0
        content_start = company_block.index("User Content")
        content_stop = company_block.index('pp-footer>')
        if content_start.present? || content_stop.present?
          first_block = company_block[content_start, content_stop]
          if first_block.include? 'More user content ('
            count_start = first_block.index('More user content (')
            count_block = first_block[count_start..first_block.length]
            count_end = count_block.index('&raquo;<')
            content_count_block = count_block[0..count_end]
            user_content = 4 + content_count_block[19..(content_count_block.length - 4)].to_i
          else
            counts = first_block.split('pp-story-item')
            user_content = counts.size - 1
          end
        end
        result["user_content_count"] = user_content.to_i if user_content.present?
      end
    rescue Exception => e
      puts "#{ e } : #{ e.backtrace.first }"
      return result
    end
    return result
  end

  def get_yahoo_ranking
    return 1000
  end

  def get_bing_ranking
    return 1000
  end
end
