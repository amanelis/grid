class GoogleSemCampaign < ActiveRecord::Base
  belongs_to :sem_campaign
  has_many :adwords_campaign_summaries, :dependent => :destroy
  has_many :adwords_ad_groups, :dependent => :destroy
  has_many :adwords_ad_summaries, :through => :adwords_ad_groups

  CAMPAIGN_REPORT_TYPE = "Campaign"
  AD_REPORT_TYPE = "Ad"
  ALL_AD_REPORT_TYPE = "All Ad"
  ALL_CAMPAIGN_REPORT_TYPE = "All Campaign"

 
  # CLASS BEHAVIOR

  def self.update_google_sem_campaign_reports_by_campaign(date = Date.yesterday, hard_update = false)
    job_status = JobStatus.create(:name => "GoogleSemCampaign.update_sem_campaign_reports_by_campaign")
    begin
      #pull the days report and save each
      (hard_update ? 30 : 6).downto(0) { |days| self.create_all_campaign_level_reports_for_google(date - days) }
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
    GroupAccount.cache_results_for_group_accounts
  end

  def self.update_google_sem_campaign_reports_by_ad(date = Date.yesterday, hard_update = false)
    job_status = JobStatus.create(:name => "GoogleSemCampaign.update_sem_campaign_reports_by_ad")
    begin
      #pull the days report and save each
      (hard_update ? 30 : 6).downto(0) { |days| self.create_all_ad_level_reports_for_google(date - days) }
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    job_status.finish_with_no_errors
    GroupAccount.cache_results_for_group_accounts
  end

  def self.create_all_campaign_level_reports_for_google(date = Date.yesterday)
    report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ?', date.strftime('%m/%d/%Y'), ALL_CAMPAIGN_REPORT_TYPE])
    new_report = SemCampaignReportStatus.new
    new_report.result = 'Started'

    if report_exists.blank?
      puts 'Started all campaign-level report the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
      new_report.pulled_on = date.strftime("%m/%d/%Y")
      new_report.provider = 'Google'
      new_report.report_type = ALL_CAMPAIGN_REPORT_TYPE
      new_report.save!

      #adwords = AdWords::API.new(AdWords::AdWordsCredentials.new( ADWORDS_CREDENTIALS ))
      #report_name = "All Campaigns- " + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      report_srv = AdWords::API.new(AdWords::AdWordsCredentials.new( ADWORDS_CREDENTIALS )).get_service('Report', 13)
      job = report_srv.module::DefinedReportJob.new
      job.selectedReportType = 'Campaign'
      job.aggregationTypes = 'Summary'
      job.name = "All Campaigns- " + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      job.selectedColumns = %w{   Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank  }
      job.startDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      job.endDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      job.crossClient = true

      cityvoice_sem_campaign = Campaign.orphanage.campaign_style
      begin
        report_srv.validateReportJob(job)
        job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
        #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
        #sleep(20)
        #report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
        rows = Nokogiri::XML(report_srv.downloadXmlReport(job_id)).xpath("//row")
        if rows.present?
          rows.each do |row|
            begin
              google_sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
              if google_sem_campaign.blank?
                google_sem_campaign = cityvoice_sem_campaign.google_sem_campaigns.build
                google_sem_campaign.reference_id = row['campaignid']
              else
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.blank?
                  client = AdwordsClient.new
                  client.account_id = google_sem_campaign.sem_campaign.account.id
                  client.name = row['acctname']
                end
                client.timezone = row['timezone']
                client.reference_id = row['customerid']
                client.save!
              end
              google_sem_campaign.name = row['campaign']
              google_sem_campaign.status = row['campStatus']
              google_sem_campaign.campaign_type = row['adwordsType']
              google_sem_campaign.save!

              #Add the Campaign Summary
              adwords_campaign_summary = AdwordsCampaignSummary.find_by_google_sem_campaign_id_and_report_date(google_sem_campaign.id, date)
              if adwords_campaign_summary.blank?
                adwords_campaign_summary = AdwordsCampaignSummary.new
                adwords_campaign_summary.google_sem_campaign_id = google_sem_campaign.id
                adwords_campaign_summary.report_date = date
              end
              adwords_campaign_summary.conv = row['conv']
              adwords_campaign_summary.cost = row['cost']
              adwords_campaign_summary.status = row['campStatus']
              adwords_campaign_summary.invalid_clicks = row['invalidClicks']
              adwords_campaign_summary.total_interactions = row['totalInteractions']
              adwords_campaign_summary.budget = row['budget']
              adwords_campaign_summary.imps = row['imps']
              adwords_campaign_summary.pos = row['pos']
              adwords_campaign_summary.cpc = row['cpc']
              adwords_campaign_summary.cpm = row['cpm']
              adwords_campaign_summary.ctr = row['ctr']
              adwords_campaign_summary.exact_match_imp_share = row['exactMatchImpShare']
              adwords_campaign_summary.imp_share = row['impShare']
              adwords_campaign_summary.lost_imp_share_budget = row['lostImpShareBudget']
              adwords_campaign_summary.lost_imp_share_rank = row['lostImpShareRank']
              adwords_campaign_summary.clicks = row['clicks']
              adwords_campaign_summary.save!
            rescue => e
              new_report.result = "Error Occurred"
              new_report.save!
              puts "Error updating campaign-level report: #{ e }"
              next
            end
          end
        end
      rescue AdWords::Error::Error => e
        new_report.result = "Error Occurred"
        new_report.save!
        puts "Error updating campaign-level report: #{ e }"
      end

      if new_report.result == 'Started'
        new_report.job_id = job_id
        new_report.result = 'Completed'
        new_report.save!
        puts 'Completed adding campaign-level report at ' + Time.now.to_s
      else
        SemCampaignReportStatus.delete(new_report.id)
        puts 'Completed with error(s) updating campaign-level report at ' + Time.now.to_s
      end

    elsif report_exists.result == "Started" && report_exists.created_at < (Date.yesterday)
      SemCampaignReportStatus.delete(report_exists.id)
    end
  end

  def self.create_all_ad_level_reports_for_google(date = Date.yesterday)
    report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ?', date.strftime('%m/%d/%Y'), ALL_AD_REPORT_TYPE])
    new_report = SemCampaignReportStatus.new
    new_report.result = 'Started'

    if report_exists.blank?
      puts 'Started all ad-level report the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
      new_report.pulled_on = date.strftime("%m/%d/%Y")
      new_report.provider = 'Google'
      new_report.report_type = ALL_AD_REPORT_TYPE
      new_report.save!

      #adwords = AdWords::API.new(AdWords::AdWordsCredentials.new( ADWORDS_CREDENTIALS ))
      #report_name = "All Ad- #{date.year.to_s}-#{date.month.to_s}-#{date.day.to_s}"
      report_srv = AdWords::API.new(AdWords::AdWordsCredentials.new( ADWORDS_CREDENTIALS )).get_service('Report', 13)
      job = report_srv.module::DefinedReportJob.new
      job.selectedReportType = 'Creative'
      job.aggregationTypes = 'Summary'
      job.name = "All Ad- #{date.year.to_s}-#{date.month.to_s}-#{date.day.to_s}"
      job.selectedColumns = %w{    AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl                                 }
      job.startDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      job.endDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
      job.crossClient = true

      cityvoice_sem_campaign = Campaign.orphanage.campaign_style
      begin
        report_srv.validateReportJob(job)
        job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
        #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
        #sleep(20)
        report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
        rows = report.xpath("//row")
        if rows.present?
          rows.each do |row|
            begin
              google_sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
              if google_sem_campaign.blank?
                google_sem_campaign = cityvoice_sem_campaign.google_sem_campaigns.build
                google_sem_campaign.reference_id = row['campaignid']
              else
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.blank?
                  client = AdwordsClient.new
                  client.account_id = google_sem_campaign.sem_campaign.account.id
                  client.name = row['acctname']
                end
                client.timezone = row['timezone']
                client.reference_id = row['customerid']
                client.save!
              end
              google_sem_campaign.name = row['campaign']
              google_sem_campaign.status = row['campStatus']
              google_sem_campaign.campaign_type = row['adwordsType']
              google_sem_campaign.save!

              #Add or Update the Ad Group
              adgroup = AdwordsAdGroup.find_by_reference_id(row["adgroupid"])
              if adgroup.blank?
                adgroup = AdwordsAdGroup.new
                adgroup.google_sem_campaign_id = google_sem_campaign.id
                adgroup.reference_id = row["adgroupid"]
              end
              adgroup.status = row["agStatus"]
              adgroup.save!

              #Add or Update the Keyword
              keyword = AdwordsKeyword.find_by_reference_id(row["keywordid"])
              if keyword.blank?
                keyword = AdwordsKeyword.new
                keyword.adwords_ad_group_id = adgroup.id
                keyword.reference_id = row["keywordid"]
              end
              keyword.descriptor = row["keyword"]
              keyword.dest_url = row["kwDestUrl"]
              keyword.status = row["kwStatus"]
              keyword.keyword_type = row["kwType"]
              keyword.save!

              #Add or Update the Ad
              ad = AdwordsAd.find_by_reference_id(row["creativeid"])
              if ad.blank?
                ad = AdwordsAd.new
                ad.adwords_ad_group_id = adgroup.id
                ad.reference_id = row["creativeid"]
              end
              ad.status = row["creativeStatus"]
              ad.dest_url = row["creativeDestUrl"]
              ad.creative_type = row["creativeType"]
              ad.headline = row["headline"]
              ad.desc1 = row["desc1"]
              ad.desc2 = row["desc2"]
              ad.dest_url = row["destUrl"]
              ad.img_name = row["imgCreativeName"]
              ad.hosting_key = row["hostingKey"]
              ad.preview = row["preview"]
              ad.vis_url = row["creativeVisUrl"]
              ad.save!

              #Add the Ad Summary
              adword = AdwordsAdSummary.find_by_adwords_ad_id_and_adwords_keyword_id_and_summary_date(ad.id, keyword.id, date)
              if adword.blank?
                adword = AdwordsAdSummary.new
                adword.adwords_ad_id = ad.id
                adword.adwords_keyword_id = keyword.id
                adword.summary_date = date
              end
              adword.conv = row["conv"]
              adword.cost = row["cost"]
              adword.budget = row["budget"]
              adword.default_conv = row["defaultConv"]
              adword.default_conv_value = row["defaultConvValue"]
              adword.first_page_cpc = row["firstPageCpc"]
              adword.imps = row["imps"]
              adword.leads = row["leads"]
              adword.lead_value = row["leadValue"]
              adword.max_content_cpc = row["maxContentCpc"]
              adword.max_cpc = row["maxCpc"]
              adword.max_cpm = row["maxCpm"]
              adword.page_views = row["pageviews"]
              adword.page_view_value = row["pageviewValue"]
              adword.ag_max_cpa = row["agMaxCpa"]
              adword.avg_conv_value = row["avgConvValue"]
              adword.pos = row["pos"]
              adword.avg_percent_played = row["avgPercentPlayed"]
              adword.bottom_position = row["bottomPosition"]
              adword.cpc = row["cpc"]
              adword.cpm = row["cpm"]
              adword.ctr = row["ctr"]
              adword.quality_score = row["qualityScore"]
              adword.purchases = row["conv"]
              adword.purchase_value = row["purchaseValue"]
              adword.sign_ups = row["signups"]
              adword.sign_up_value = row["signupValue"]
              adword.top_position = row["topPosition"]
              adword.conv_value = row["convValue"]
              adword.transactions = row["transactions"]
              adword.conv_vpc = row["convVpc"]
              adword.value_cost_ratio = row["valueCostRatio"]
              adword.video_playbacks = row["videoPlaybacks"]
              adword.video_playbacks_through_100_percent = row["videoPlaybacksThrough100Percent"]
              adword.video_playbacks_through_75_percent = row["videoPlaybacksThrough75Percent"]
              adword.video_playbacks_through_50_percent = row["videoPlaybacksThrough50Percent"]
              adword.video_playbacks_through_25_percent = row["videoPlaybacksThrough25Percent"]
              adword.video_skips = row["videoSkips"]
              adword.keyword_min_cpc = row["keywordMinCpc"]
              adword.cpt = row["cpt"]
              adword.cost_per_video_playback = row["costPerVideoPlayback"]
              adword.conv_rate = row["convRate"]
              adword.cost_per_conv = row["costPerConv"]
              adword.clicks = row["clicks"]
              adword.save!

            rescue => e
              new_report.result = "Error Occurred"
              new_report.save!
              puts "Error updating ad-level report: #{ e }"
              next
            end
          end
        end
      rescue AdWords::Error::Error => e
        new_report.result = "Error Occurred"
        new_report.save!
        puts "Error updating ad-level report: #{ e }"
      end

      if new_report.result == 'Started'
        new_report.job_id = job_id
        new_report.result = 'Completed'
        new_report.save!
        puts 'Completed adding ad-level report at ' + Time.now.to_s
      else
        SemCampaignReportStatus.delete(new_report.id)
        puts 'Completed with error(s) updating ad-level report at ' + Time.now.to_s
      end

    elsif report_exists.result == "Started" && report_exists.created_at < (Date.yesterday)
      SemCampaignReportStatus.delete(report_exists.id)
    end
  end


  # INSTANCE BEHAVIOR

  def create_campaign_level_sem_campaign_report_for_google(date)
    existing_report = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ? AND sem_campaign_id = ?', date.strftime('%m/%d/%Y'), CAMPAIGN_REPORT_TYPE, self.id])

    if existing_report.blank?
      campaign_array = self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.reference_id }
      if campaign_array.present?
        new_report = SemCampaignReportStatus.new
        new_report.result = 'Started'
        puts 'Started campaign-level report for: ' + self.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        new_report.sem_campaign_id = self.id
        new_report.pulled_on = date.strftime('%m/%d/%Y')
        new_report.provider = 'Google'
        new_report.report_type = CAMPAIGN_REPORT_TYPE
        new_report.save!
        begin
          adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))
          report_name = self.name + ': ' + date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          report_srv = adwords.get_service('Report', 13)
          job = report_srv.module::DefinedReportJob.new
          job.selectedReportType = 'Campaign'
          job.aggregationTypes = 'Summary'
          job.name = report_name
          job.selectedColumns = %w{ Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank                                 }
          job.startDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.endDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.crossClient = true
          job.campaigns = campaign_array

          puts 'Started report_srv.validateReportJob(job)'
          time1 = Time.now
          report_srv.validateReportJob(job)
          puts 'Ended report_srv.validateReportJob(job)'
          time2 = Time.now
          puts "Time to run: #{time2 - time1} seconds"

          puts 'Started job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn'
          time3 = Time.now
          job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
          puts 'Ended job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn'
          time4 = Time.now
          puts "Time to run: #{time4 - time3} seconds"

          #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
          puts 'Started report_data = report_srv.downloadXmlReport(job_id)'
          time5 = Time.now
          report_data = report_srv.downloadXmlReport(job_id)
          puts 'Ended report_data = report_srv.downloadXmlReport(job_id)'
          time6 = Time.now
          puts "Time to run: #{time6 - time5} seconds"

          puts 'Started report = Nokogiri::XML(report_data)'
          time7 = Time.now
          report = Nokogiri::XML(report_data)
          puts 'Ended report = Nokogiri::XML(report_data)'
          time8 = Time.now
          puts "Time to run: #{time8 - time7} seconds"

          puts 'Started rows = report.xpath'
          time9 = Time.now
          rows = report.xpath('//row')
          puts 'Ended rows = report.xpath'
          time10 = Time.now
          puts "Time to run: #{time10 - time9} seconds"

          puts 'Started Loop of Rows'
          time11 = Time.now
          if rows.present?
            rows.each do |row|
              begin
                #Add or Update the Client
                adwords_client = AdwordsClient.find_by_name(row['acctname'])
                if adwords_client.blank?
                  adwords_client = AdwordsClient.new
                  adwords_client.account_id = self.campaign.account.id
                  adwords_client.name = row['acctname']
                end
                adwords_client.timezone = row['timezone']
                adwords_client.reference_id = row['customerid']
                adwords_client.save!

                #Add or Update the Campaign
                google_sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                google_sem_campaign.name = row['campaign']
                google_sem_campaign.status = row['campStatus']
                google_sem_campaign.campaign_type = row['adwordsType']
                google_sem_campaign.save!

                adwords_campaign_summary = AdwordsCampaignSummary.find_by_google_sem_campaign_id_and_report_date(google_sem_campaign.id, date)
                if adwords_campaign_summary.blank?
                  adwords_campaign_summary = AdwordsCampaignSummary.new
                  adwords_campaign_summary.google_sem_campaign_id = google_sem_campaign.id
                  adwords_campaign_summary.report_date = date
                end
                adwords_campaign_summary.conv = row['conv']
                adwords_campaign_summary.cost = row['cost']
                adwords_campaign_summary.status = row['campStatus']
                adwords_campaign_summary.invalid_clicks = row['invalidClicks']
                adwords_campaign_summary.total_interactions = row['totalInteractions']
                adwords_campaign_summary.budget = row['budget']
                adwords_campaign_summary.imps = row['imps']
                adwords_campaign_summary.pos = row['pos']
                adwords_campaign_summary.cpc = row['cpc']
                adwords_campaign_summary.cpm = row['cpm']
                adwords_campaign_summary.ctr = row['ctr']
                adwords_campaign_summary.exact_match_imp_share = row['exactMatchImpShare']
                adwords_campaign_summary.imp_share = row['impShare']
                adwords_campaign_summary.lost_imp_share_budget = row['lostImpShareBudget']
                adwords_campaign_summary.lost_imp_share_rank = row['lostImpShareRank']
                adwords_campaign_summary.clicks = row['clicks']
                adwords_campaign_summary.save!
              rescue => e
                new_report.result = 'Error Occurred'
                new_report.save!
                puts "Error updating campaign-level report: #{ e }"
                next
              end
            end
          end
          puts 'Ended Loop of Rows'
          time12 = Time.now
          puts "Time to run: #{time12 - time11} seconds"
        rescue AdWords::Error::Error => e
          new_report.result = 'Error Occurred'
          new_report.save!
          puts "Error updating campaign-level report: #{ e }"
        end
        if new_report.result == 'Started'
          new_report.job_id = job_id
          new_report.result = 'Completed'
          new_report.save!
          puts 'Completed adding campaign-level report at ' + Time.now.to_s
        else
          SemCampaignReportStatus.delete(new_report.id)
          puts 'Completed with error(s) updating campaign-level report at ' + Time.now.to_s
        end
      else
        puts 'No campaign-level report found for: ' + self.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
      end
    elsif existing_report.result == 'Started' && existing_report.created_at < (Date.yesterday)
      SemCampaignReportStatus.delete(existing_report.id)
    end
  end

  def create_ad_level_sem_campaign_report_for_google(date)
    existing_report = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ? AND sem_campaign_id = ?', date.strftime('%m/%d/%Y'), AD_REPORT_TYPE, self.id])

    if existing_report.blank?
      campaign_array = self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.reference_id }
      if campaign_array.present?
        new_report = SemCampaignReportStatus.new
        new_report.result = 'Started'
        puts 'Started ad-level report for: ' + self.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        new_report.sem_campaign_id = self.id
        new_report.pulled_on = date.strftime("%m/%d/%Y")
        new_report.provider = 'Google'
        new_report.report_type = AD_REPORT_TYPE
        new_report.save!

        adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => campaign.developer_token, 'applicationToken' => campaign.application_token, 'useragent' => campaign.user_agent, 'password' => campaign.password, 'email' => campaign.email, 'clientEmail' => campaign.client_email, 'environment' => 'PRODUCTION', }))
        report_name = "Ad- " + self.name + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        report_srv = adwords.get_service('Report', 13)
        job = report_srv.module::DefinedReportJob.new
        job.selectedReportType = 'Creative'
        job.aggregationTypes = 'Summary'
        job.name = report_name
        job.selectedColumns = %w{    AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl                                 }
        job.startDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        job.endDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        job.crossClient = true
        job.campaigns = campaign_array

        begin
          report_srv.validateReportJob(job)
          job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
          #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
          #sleep(20)
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
          rows = report.xpath("//row")
          if rows.present?
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.blank?
                  client = AdwordsClient.new
                  client.account_id = self.campaign.account.id
                  client.name = row['acctname']
                end
                client.timezone = row['timezone']
                client.reference_id = row['customerid']
                client.save!

                #Add or Update the Campaign
                sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                sem_campaign.name = row['campaign']
                sem_campaign.status = row['campStatus']
                sem_campaign.campaign_type = row['adwordsType']
                sem_campaign.save!

                #Add or Update the Ad Group
                adgroup = AdwordsAdGroup.find_by_reference_id(row["adgroupid"])
                if adgroup.blank?
                  adgroup = AdwordsAdGroup.new
                  adgroup.google_sem_campaign_id = sem_campaign.id
                  adgroup.reference_id = row["adgroupid"]
                end
                adgroup.status = row["agStatus"]
                adgroup.save!

                #Add or Update the Keyword
                keyword = AdwordsKeyword.find_by_reference_id(row["keywordid"])
                if keyword.blank?
                  keyword = AdwordsKeyword.new
                  keyword.adwords_ad_group_id = adgroup.id
                  keyword.reference_id = row["keywordid"]
                end
                keyword.descriptor = row["keyword"]
                keyword.dest_url = row["kwDestUrl"]
                keyword.status = row["kwStatus"]
                keyword.keyword_type = row["kwType"]
                keyword.save!

                #Add or Update the Ad
                ad = AdwordsAd.find_by_reference_id(row["creativeid"])
                if ad.blank?
                  ad = AdwordsAd.new
                  ad.adwords_ad_group_id = adgroup.id
                  ad.reference_id = row["creativeid"]
                end
                ad.status = row["creativeStatus"]
                ad.dest_url = row["creativeDestUrl"]
                ad.creative_type = row["creativeType"]
                ad.headline = row["headline"]
                ad.desc1 = row["desc1"]
                ad.desc2 = row["desc2"]
                ad.dest_url = row["destUrl"]
                ad.img_name = row["imgCreativeName"]
                ad.hosting_key = row["hostingKey"]
                ad.preview = row["preview"]
                ad.vis_url = row["creativeVisUrl"]
                ad.save!

                #Add the Ad Summary
                adword = AdwordsAdSummary.find_by_adwords_ad_id_and_summary_date(ad.id, date)
                if adword.blank?
                  adword = AdwordsAdSummary.new
                  adword.adwords_ad_id = ad.id
                  adword.summary_date = date
                end
                adword.conv = row["conv"]
                adword.cost = row["cost"]
                adword.budget = row["budget"]
                adword.default_conv = row["defaultConv"]
                adword.default_conv_value = row["defaultConvValue"]
                adword.first_page_cpc = row["firstPageCpc"]
                adword.imps = row["imps"]
                adword.leads = row["leads"]
                adword.lead_value = row["leadValue"]
                adword.max_content_cpc = row["maxContentCpc"]
                adword.max_cpc = row["maxCpc"]
                adword.max_cpm = row["maxCpm"]
                adword.page_views = row["pageviews"]
                adword.page_view_value = row["pageviewValue"]
                adword.ag_max_cpa = row["agMaxCpa"]
                adword.avg_conv_value = row["avgConvValue"]
                adword.pos = row["pos"]
                adword.avg_percent_played = row["avgPercentPlayed"]
                adword.bottom_position = row["bottomPosition"]
                adword.cpc = row["cpc"]
                adword.cpm = row["cpm"]
                adword.ctr = row["ctr"]
                adword.quality_score = row["qualityScore"]
                adword.purchases = row["conv"]
                adword.purchase_value = row["purchaseValue"]
                adword.sign_ups = row["signups"]
                adword.sign_up_value = row["signupValue"]
                adword.top_position = row["topPosition"]
                adword.conv_value = row["convValue"]
                adword.transactions = row["transactions"]
                adword.conv_vpc = row["convVpc"]
                adword.value_cost_ratio = row["valueCostRatio"]
                adword.video_playbacks = row["videoPlaybacks"]
                adword.video_playbacks_through_100_percent = row["videoPlaybacksThrough100Percent"]
                adword.video_playbacks_through_75_percent = row["videoPlaybacksThrough75Percent"]
                adword.video_playbacks_through_50_percent = row["videoPlaybacksThrough50Percent"]
                adword.video_playbacks_through_25_percent = row["videoPlaybacksThrough25Percent"]
                adword.video_skips = row["videoSkips"]
                adword.keyword_min_cpc = row["keywordMinCpc"]
                adword.cpt = row["cpt"]
                adword.cost_per_video_playback = row["costPerVideoPlayback"]
                adword.conv_rate = row["convRate"]
                adword.cost_per_conv = row["costPerConv"]
                adword.clicks = row["clicks"]
                adword.save!

              rescue => e
                new_report.result = "Error Occurred"
                new_report.save!
                puts "Error updating ad-level report: #{ e }"
                next
              end
            end
          end
        rescue AdWords::Error::Error => e
          new_report.result = "Error Occurred"
          new_report.save!
          puts "Error updating ad-level report: #{ e }"
        end
        if new_report.result == 'Started'
          new_report.job_id = job_id
          new_report.result = 'Completed'
          new_report.save!
          puts 'Completed adding ad-level report at ' + Time.now.to_s
        else
          SemCampaignReportStatus.delete(new_report.id)
          puts 'Completed with error(s) updating ad-level report at ' + Time.now.to_s
        end
      else
        puts 'No ad-level report found for: ' + self.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
      end
    elsif existing_report.result == "Started" && existing_report.created_at < (Date.yesterday)
      SemCampaignReportStatus.delete(existing_report.id)
    end
  end
  
  def rake
    (rake = self.sem_campaign.rake).present? ? rake : 0.0
  end
  
  def rake_percentage_for(date = Date.today)
    self.sem_campaign.channel.rake_percentage_for(date)
  end

  def spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (self.cost_between(start_date, end_date) * 100.0) / (100.0 - self.rake)
  end

  def spend_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (self.cost_from_ads_between(start_date, end_date) * 100.0) / (100.0 - self.rake)
  end

  def total_spend_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (start_date..end_date).sum { |date| (self.cost_between(date, date) * 100.0) / (100.0 - self.rake_percentage_for(date)) }
  end

  def total_spend_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (start_date..end_date).sum { |date| (self.cost_from_ads_between(date, date) * 100.0) / (100.0 - self.rake_percentage_for(date)) }
  end

  def cost_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:cost) / 1000000.0
  end

  def cost_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.cost_between(start_date, end_date) }
  end

  def clicks_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:clicks)
  end

  def clicks_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.clicks_between(start_date, end_date) }
  end

  def impressions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:imps)
  end

  def impressions_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.impressions_between(start_date, end_date) }
  end

  def click_through_rate_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (impressions = self.impressions_between(start_date, end_date)) > 0 ? self.clicks_between(start_date, end_date).to_f / impressions : 0.0
  end

  def click_through_rate_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (impressions = self.impressions_from_ads_between(start_date, end_date)) > 0 ? self.clicks_from_ads_between(start_date, end_date).to_f / impressions : 0.0
  end

  def average_position_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:pos).to_f / count : 0.0
  end

  def average_position_from_ads_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.summaries_between(start_date, end_date) }) > 0 ? self.adwords_ad_groups.to_a.sum { |adwords_ad_group| adwords_ad_group.positions_between(start_date, end_date) }.to_f / count : 0.0
  end
  
  def average_cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:cpc).to_f / count : 0.0
  end
  
  def average_cost_per_impression_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:cpm).to_f / count : 0.0
  end
  
  def average_impression_share_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:imp_share).to_f / count : 0.0
  end
  
  def average_exact_match_impression_share_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_campaign_summaries.between(start_date, end_date).count) > 0 ? self.adwords_campaign_summaries.between(start_date, end_date).sum(:exact_match_imp_share).to_f / count : 0.0
  end

  def number_of_clicks_by_date
    self.adwords_campaign_summaries.sum(:clicks, :group => "date(report_date)", :order =>"report_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:clicks => value}; data }
  end

  def number_of_impressions_by_date
    self.adwords_campaign_summaries.sum(:imps, :group => "date(report_date)", :order =>"report_date ASC").inject({}) { |data, (key, value)| data[key.to_date] = {:impressions => value}; data }
  end

  def number_of_clicks_from_ads_by_date
    Utilities.merge_and_sum_timeline_data(self.adwords_ad_groups.collect { |adwords_ad_group| adwords_ad_group.number_of_clicks_by_date }, :clicks)
  end

  def number_of_impressions_from_ads_by_date
    Utilities.merge_and_sum_timeline_data(self.adwords_ad_groups.collect { |adwords_ad_group| adwords_ad_group.number_of_impressions_by_date }, :impressions)
  end
  
  def average_cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (clicks = self.clicks_between(start_date, end_date)) > 0 ? self.spend_between(start_date, end_date).to_f / clicks : 0.0
  end
  
  def true_average_cost_per_click_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (clicks = self.clicks_between(start_date, end_date)) > 0 ? self.cost_between(start_date, end_date).to_f / clicks : 0.0
  end
  
  def average_quality_score_between(start_date = Date.yesterday, end_date = Date.yesterday)
    (count = self.adwords_ad_groups.count) > 0 ? (self.adwords_ad_groups.collect {|adwords_ad_group| adwords_ad_group.average_quality_score_between(start_date, end_date)}).sum / count : 0.0
  end

end
