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
    search_keyword = self.descriptor.gsub(" ", "+")
    startpage = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
    googleurl = "http://maps.google.com/maps?hl=en&um=1&ie=UTF-8&q=" + search_keyword + "&fb=1&gl=us&view=text&cd=2&sa=N"
    pagenum = 0
    result = {"result" => 1000, "company_name" => "NA", "address" => "NA", "phone" => "NA", "page" => "NA", "review_count" => 0, "coupon_count" => 0, "citation_count" => 0, "user_content_count" => 0}

    company = self.maps_campaign.company_name.present? ? self.maps_campaign.company_name : self.campaign.account.name

    begin
      20.times do
        if result["result"] == 1000
          strsource = HTTParty.get(googleurl)
          #Get all 10 results
          resultsstart = strsource.index("id=title")
          resultsstop = strsource.index("pw res")
          results = strsource[resultsstart..resultsstop]
          wholepage = results.split("id=title")
          wholepage.delete_at(0)

          wholepage.each do |resultitem|
                           #Get Page
            page = "NA"
            pageblock = ""
            pagestart = resultitem.index("href=/maps")
            pagestop = resultitem.index(" log=miwd")
            if pagestart.present? && pagestop.present?
              page = resultitem[pagestart..pagestop]
              page = "http://maps.google.com" + page[5..page.length-1]
            end

            #Get Company
            companystart = resultitem.index("dir=ltr>")
            companystop = resultitem.index("</span>")
            companytemp = resultitem[companystart..companystop]
            companyname = companytemp[8..companytemp.length-2]
            companyname = companyname.sub("<b>", "")
            companyname = companyname.sub("</b>", "")
            companyname = companyname.sub("&amp;", "&")
            companyname = companyname.sub("&#39;", "'")

            #Get Address
            address = "None"
            addressblock = nil
            blockstop = nil
            addressstart = resultitem.index("id=adr")
            addressstop = resultitem.index("class=tel")
            if addressstart.present? && addressstop.present?
              addressblock = resultitem[addressstart..addressstop]
              blockstop = addressblock.index("</span>")
              address = addressblock[0..blockstop]
              address = address[15..address.length-2]
            end

            #Get Phone
            phone = "NA"
            phonestart = resultitem.index("class=tel")
            if phonestart.present?
              phoneblock = resultitem[phonestart, resultitem.length-1]
              phonetemp = phoneblock.index("</span>")
              phone = phoneblock[0..phonetemp]
              phone = phone[11..phone.length-2]
              phone = phone.sub(") ", "")
              phone = phone.sub("-", "")
            end

            #Get Number of reviews
            review = "NA"
            reviewstart = resultitem.index("rp_review")
            if reviewstart.present?
              firstblock = resultitem[reviewstart, resultitem.length-1]
              reviewstop = firstblock.index("</a>")
              reviewblock = firstblock[20, (reviewstop - 27)]
              review = reviewblock
            end

            #Get Number of coupons
            coupons = "NA"
            couponstart = resultitem.index("id=coupon")
            if couponstart.present?
              firstblock = resultitem[couponstart, resultitem.length-1]
              couponstop = firstblock.index("</a>")
              couponblock = firstblock[72, (couponstop - 80)]
              coupons = couponblock
            end

            if companyname.index(company).present?
              placement = pagenum + (wholepage.index(resultitem) + 1)

              #Get Citations
              citations = "0"
              begin
                url = URI.escape(page.to_s)
                actual_page = HTTParty.get(url)
                citationstart = actual_page.index("More about this place")
                if citationstart.present?
                  firstblock = actual_page[citationstart, actual_page.length-1]
                  citationstop = firstblock.index(") &raquo;")
                  if citationstop.blank?
                    stop = firstblock.index("User Content")
                    if stop.present?
                      nextblock = firstblock[0, stop]
                      items = nextblock.split("pp-story-item")
                      citations = items.count - 1
                    else
                      stop = firstblock.index("pp-footer")
                      nextblock = firstblock[0, stop]
                      items = nextblock.split("pp-story-item")
                      citations = items.count - 1
                    end
                  else
                    nextstart = firstblock.index("More (")
                    citationblock = firstblock[nextstart, citationstop]
                    cit_string = citationblock.gsub("More (", "")
                    citations = cit_string.to_i + 5 if cit_string.present?
                  end
                end
              rescue
                puts "Error in Citation Block"
              end

              #Get User Content
              begin
                user_content = "0"
                contentstart = actual_page.index("User Content")
                if contentstart.present?
                  firstblock = actual_page[contentstart, actual_page.length-1]
                  contentstop = firstblock.index("More user content (")

                  if contentstop.blank?
                    contentstop = firstblock.index("Terms of Use")
                    contentblock = firstblock[0, contentstop]
                    contents = contentblock.split("pp-story-item")
                    user_content = contents.count - 1
                  else
                    contentblock = actual_page[0, contentstop + 10]
                    user_content = contentblock.to_i + 5 if contentblock.present?
                  end
                end
              rescue
                puts "Error in User Content"
              end

              result["result"] = placement
              result["company_name"] = companyname
              result["address"] = address
              result["phone"] = phone.to_s
              result["page"] = page
              result["review_count"] = review.to_i if review.present?
              result["coupon_count"] = coupons.to_i if coupons.present?
              result["citation_count"] = citations.to_i if citations.present?
              result["user_content_count"] = user_content.to_i if user_content.present?
            end
          end
        end
        pagenum += 10
        googleurl = startpage + "&start=" + pagenum.to_s()
      end
    rescue Exception => e
      puts "#{ e } (#{ e.class })!"
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
