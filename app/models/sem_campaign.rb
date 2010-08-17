class SemCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  has_many :google_sem_campaigns
  has_many :sem_campaign_report_statuses

  def self.update_sem_campaign_reports_by_campaign(hard_update = false, date = Date.today)
    sem_campaigns = SemCampaign.all
    sem_campaigns.each do |sem_campaign|
      span = 30
      if hard_update == false
        span = 7
      end
      #pull the days report and save each
      while span != 0
        pull_date = date - span.days
        sem_campaign.create_sem_campaign_report_for_google(pull_date, 'Campaign')
        span -= 1
      end
    end
  end

  def self.update_sem_campaign_reports_by_ad(hard_update = false, date = Date.today)
    sem_campaigns = SemCampaign.all
    sem_campaigns.each do |sem_campaign|
      span = 30
      if hard_update == false
        span = 7
      end
      #pull the days report and save each
      while span != 0
        pull_date = date - span.days
        sem_campaign.create_sem_campaign_report_for_google(pull_date, 'Ad')
        span -= 1
      end
    end
  end

  def create_sem_campaign_report_for_google(date, report_type = 'Campaign')
    campaign_array = self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.reference_id }
    report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ? AND sem_campaign_id = ?', date.strftime('%m/%d/%Y'), report_type, self.id])
    job_id = 0
    new_report = SemCampaignReportStatus.new
    new_report.result = 'Started'

    if report_type == 'Campaign'
      if report_exists == nil && campaign_array.present?
        puts 'Started Report for: ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        new_report.pulled_on = date.strftime('%m/%d/%Y')
        new_report.report_type = 'Campaign'
        new_report.provider = 'Google'
        new_report.sem_campaign_id = self.id
        new_report.save
        begin
          adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))
          report_name = self.name + ': ' + date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          report_srv = adwords.get_service('Report', 13)
          job = report_srv.module::DefinedReportJob.new
          job.selectedReportType = 'Campaign'
          job.aggregationTypes = 'Summary'
          job.name = report_name
          job.selectedColumns = %w{          Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank          }
          job.startDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.endDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.crossClient = true
          job.campaigns = campaign_array

          report_srv.validateReportJob(job)

          job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
          #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))

          rows = report.xpath('//row')
          if rows.size < (job.campaigns.size + 5)
            new_report.result = 'Completed'
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.present?
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                else
                  client = AdwordsClient.new
                  client.name = row['acctname']
                  client.account_id = self.campaign.account.id
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                end

                #Add or Update the Campaign
                sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                if sem_campaign.present?
                  sem_campaign.name = row['campaign']
                  sem_campaign.status = row['campStatus']
                  sem_campaign.campaign_type = row['adwordsType']
                  sem_campaign.save
                end

                adword = AdwordsCampaignSummary.find_by_google_sem_campaign_id_and_report_date(sem_campaign.id, date)
                if adword.present?
                  adword.conv = row['conv']
                  adword.cost = row['cost']
                  adword.status = row['campStatus']
                  adword.invalid_clicks = row['invalidClicks']
                  adword.total_interactions = row['totalInteractions']
                  adword.budget = row['budget']
                  adword.imps = row['imps']
                  adword.pos = row['pos']
                  adword.cpc = row['cpc']
                  adword.cpm = row['cpm']
                  adword.ctr = row['ctr']
                  adword.exact_match_imp_share = row['exactMatchImpShare']
                  adword.imp_share = row['impShare']
                  adword.lost_imp_share_budget = row['lostImpShareBudget']
                  adword.lost_imp_share_rank = row['lostImpShareRank']
                  adword.clicks = row['clicks']
                  adword.save
                else
                  adword = AdwordsCampaignSummary.new
                  adword.google_sem_campaign_id = sem_campaign.id
                  adword.report_date = date
                  adword.conv = row['conv']
                  adword.cost = row['cost']
                  adword.status = row['campStatus']
                  adword.invalid_clicks = row['invalidClicks']
                  adword.total_interactions = row['totalInteractions']
                  adword.budget = row['budget']
                  adword.imps = row['imps']
                  adword.pos = row['pos']
                  adword.cpc = row['cpc']
                  adword.cpm = row['cpm']
                  adword.ctr = row['ctr']
                  adword.exact_match_imp_share = row['exactMatchImpShare']
                  adword.imp_share = row['impShare']
                  adword.lost_imp_share_budget = row['lostImpShareBudget']
                  adword.lost_imp_share_rank = row['lostImpShareRank']
                  adword.clicks = row['clicks']
                  adword.save

                end
              rescue
                new_report.result = 'Error Occured'
                next
              end
            end
          end
          new_report.job_id = job_id
          new_report.save
          puts 'Added Report for: ' + campaign.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        rescue AdWords::Error::Error => e
          puts 'Error Updating report: %s' % e + ' at ' + Time.now.to_s
          new_report.result = 'Error Occured'
          new_report.job_id = job_id
          new_report.save
        end
      elsif report_exists.result == 'Error Occured'
        begin
          report_exists.result = 'Started'
          report_exists.save
          report_name = campaign.name + ': ' + date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))
          report_srv = adwords.get_service('Report', 13)
          job_id = report_exists.job_id
          if job_id == nil
            self.name + ': ' + date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
            job = report_srv.module::DefinedReportJob.new
            job.selectedReportType = 'Campaign'
            job.aggregationTypes = 'Summary'
            job.name = report_name
            job.selectedColumns = %w{          Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank          }
            job.startDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
            job.endDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
            job.crossClient = true
            job.campaigns = campaign_array

            report_srv.validateReportJob(job)

            job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
            #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
            sleep(15)
          end
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
          rows = report.xpath('//row')
          if rows.size < (campaign_array.size + 5)
            report_exists.result = 'Completed'
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.present?
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                else
                  client = AdwordsClient.new
                  client.name = row['acctname']
                  client.account_id = self.campaign.account.id
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                end

                #Add or Update the Campaign
                sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                if sem_campaign.present?
                  sem_campaign.name = row['campaign']
                  sem_campaign.status = row['campStatus']
                  sem_campaign.campaign_type = row['adwordsType']
                  sem_campaign.save
                end

                adword = AdwordsCampaignSummary.find_by_google_sem_campaign_id_and_report_date(sem_campaign.id, date)
                if adword.present?
                  adword.conv = row['conv']
                  adword.cost = row['cost']
                  adword.status = row['campStatus']
                  adword.invalid_clicks = row['invalidClicks']
                  adword.total_interactions = row['totalInteractions']
                  adword.budget = row['budget']
                  adword.imps = row['imps']
                  adword.pos = row['pos']
                  adword.cpc = row['cpc']
                  adword.cpm = row['cpm']
                  adword.ctr = row['ctr']
                  adword.exact_match_imp_share = row['exactMatchImpShare']
                  adword.imp_share = row['impShare']
                  adword.lost_imp_share_budget = row['lostImpShareBudget']
                  adword.lost_imp_share_rank = row['lostImpShareRank']
                  adword.clicks = row['clicks']
                  adword.save
                else
                  adword = AdwordsCampaignSummary.new
                  adword.google_sem_campaign_id = sem_campaign.id
                  adword.report_date = date
                  adword.conv = row['conv']
                  adword.cost = row['cost']
                  adword.status = row['campStatus']
                  adword.invalid_clicks = row['invalidClicks']
                  adword.total_interactions = row['totalInteractions']
                  adword.budget = row['budget']
                  adword.imps = row['imps']
                  adword.pos = row['pos']
                  adword.cpc = row['cpc']
                  adword.cpm = row['cpm']
                  adword.ctr = row['ctr']
                  adword.exact_match_imp_share = row['exactMatchImpShare']
                  adword.imp_share = row['impShare']
                  adword.lost_imp_share_budget = row['lostImpShareBudget']
                  adword.lost_imp_share_rank = row['lostImpShareRank']
                  adword.clicks = row['clicks']
                  adword.save

                end
              rescue
                new_report.result = 'Error Occured'
                next
              end
            end
          end
          report_exists.pulled_on = date.strftime('%m/%d/%Y')
          report_exists.save
          puts 'Added Report for: ' + campaign.name + ' for the date ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        rescue AdWords::Error::Error => e
          puts 'Error Updating report: %s' % e + ' at ' + Time.now.to_s
          report_exists.result = 'Error Occured'
          report_exists.report_type = 'Campaign'
          report_exists.provider = 'Google'
          report_exists.job_id = report_exists.job_id
          report_exists.save
        end
      elsif report_exists.result == 'Started' && report_exists.created_at < (Date.today - 1.days)
        SemCampaignReportStatus.delete(report_exists.id)
      end
      #PULL THE AD REPORT
    elsif report_type == 'Ad'
      report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ? AND sem_campaign_id = ?', date.strftime('%m/%d/%Y'), report_type, self.id])
      job_id = 0
      new_report = SemCampaignReportStatus.new

      if report_exists == nil
        new_report.sem_campaign_id = self.id
        new_report.pulled_on = date.strftime("%m/%d/%Y")
        new_report.result = "Started"
        new_report.provider = 'Google'
        new_report.report_type = "Ad"
        new_report.save
        puts "Started Report for: " + date.strftime("%m/%d/%Y") + " at " + Time.now.to_s

        adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))
        report_name = "Ad- " + self.name + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        report_srv = adwords.get_service('Report', 13)
        job = report_srv.module::DefinedReportJob.new
        job.selectedReportType = 'Creative'
        job.aggregationTypes = 'Summary'
        job.name = report_name
        job.selectedColumns = %w{         AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl          }
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
          if rows.size < (job.campaigns.size + 5)
            new_report.result = 'Completed'
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.present?
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                else
                  client = AdwordsClient.new
                  client.name = row['acctname']
                  client.account_id = self.campaign.account.id
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                end

                #Add or Update the Campaign
                sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                if sem_campaign.present?
                  sem_campaign.name = row['campaign']
                  sem_campaign.status = row['campStatus']
                  sem_campaign.campaign_type = row['adwordsType']
                  sem_campaign.save
                end

                #Add or Update the Ad Group
                adgroup = AdwordsAdGroup.find_by_reference_id(row["adgroupid"])
                if adgroup.present?
                  adgroup.google_sem_campaign_id = sem_campaign.id
                  adgroup.status = row["agStatus"]
                  adgroup.save
                else
                  adgroup = AdwordsAdGroup.new
                  adgroup.reference_id = row["adgroupid"]
                  adgroup.google_sem_campaign_id = sem_campaign.id
                  adgroup.status = row["agStatus"]
                  adgroup.save
                end

                #Add or Update the Keyword
                keyword = AdwordsKeyword.find_by_reference_id(row["keywordid"])
                if keyword.present?
                  keyword.adwords_ad_group_id = adgroup.id
                  keyword.descriptor = row["keyword"]
                  keyword.dest_url = row["kwDestUrl"]
                  keyword.status = row["kwStatus"]
                  keyword.keyword_type = row["kwType"]
                  keyword.save
                else
                  keyword = AdwordsKeyword.new
                  keyword.reference_id = row["keywordid"]
                  keyword.adwords_ad_group_id = adgroup.id
                  keyword.descriptor = row["keyword"]
                  keyword.dest_url = row["kwDestUrl"]
                  keyword.status = row["kwStatus"]
                  keyword.keyword_type = row["kwType"]
                  keyword.save
                end

                #Add or Update the Ad
                ad = AdwordsAd.find_by_reference_id(row["creativeid"])
                if ad.present?
                  ad.adwords_ad_group_id = adgroup.id
                  ad.status = row["creativeStatus"]
                  ad.dest_url = row["creativeDestUrl"]
                  ad.creative_type = row["creativeType"]
                  ad.headline = row["headline"]
                  ad.desc1 = row["desc1"]
                  ad.desc2 = row["desc2"]
                  ad.dest_url = row["destUrl"]
                  ad.img_name = row["img_name"]
                  ad.hosting_key = row["hosting_key"]
                  ad.preview = row["preview"]
                  ad.vis_url = row["vis_url"]
                else
                  ad = AdwordsAd.new
                  ad.reference_id = row["creativeid"]
                  ad.adwords_ad_group_id = adgroup.id
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
                  ad.save
                end

                #Add the Ad Summary
                adword = AdwordsAdSummary.find_by_adwords_ad_id_and_summary_date(ad.id, date)
                if adword.present?
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
                  adword.save
                else
                  adword = AdwordsAdSummary.new
                  adword.adwords_ad_id = ad.id
                  adword.summary_date = date
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
                  adword.save
                end
              rescue AdWords::Error::Error => e
                puts 'Error Parsing report: %s' % e + " at " + Time.now.to_s
                new_report.result = "Error Occured"
                new_report.job_id = job_id
                new_report.save
              end
            end
            new_report.pulled_on = date.strftime("%m/%d/%Y")
            new_report.result = "Completed"
            new_report.job_id = job_id
          end
          new_report.save
          puts "Completed Report for: " + date.strftime("%m/%d/%Y") + " at " + Time.now.to_s
        rescue AdWords::Error::Error => e
          puts 'Error Updating report: %s' % e + " at " + Time.now.to_s
          new_report.result = "Error Occured"
          new_report.job_id = job_id
          new_report.save
        end
      elsif report_exists.result == "Error Occured"
        report_exists.result = "Started"
        report_exists.save
        puts "Started Report for: " + date.strftime("%m/%d/%Y") + " Again" + " at " + Time.now.to_s
        adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))

        report_srv = adwords.get_service('Report', 13)
        job_id = report_exists.job_id
        if job_id == nil
          report_name = "Ad- " + self.name + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
          report_srv = adwords.get_service('Report', 13)
          job = report_srv.module::DefinedReportJob.new
          job.selectedReportType = 'Creative'
          job.aggregationTypes = 'Summary'
          job.name = report_name
          job.selectedColumns = %w{         AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl          }
          job.startDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
          job.endDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
          job.crossClient = true
          job.campaigns = campaign_array
        end

        begin
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
          rows = report.xpath("//row")
          if rows.size < (campaign_array.size + 5)
            new_report.result = 'Completed'
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_by_name(row['acctname'])
                if client.present?
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                else
                  client = AdwordsClient.new
                  client.name = row['acctname']
                  client.account_id = self.campaign.account.id
                  client.timezone = row['timezone']
                  client.reference_id = row['customerid']
                  client.save
                end

                #Add or Update the Campaign
                sem_campaign = GoogleSemCampaign.find_by_reference_id(row['campaignid'])
                if sem_campaign.present?
                  sem_campaign.name = row['campaign']
                  sem_campaign.status = row['campStatus']
                  sem_campaign.campaign_type = row['adwordsType']
                  sem_campaign.save
                end

                #Add or Update the Ad Group
                adgroup = AdwordsAdGroup.find_by_reference_id(row["adgroupid"])
                if adgroup.present?
                  adgroup.google_sem_campaign_id = sem_campaign.id
                  adgroup.status = row["agStatus"]
                  adgroup.save
                else
                  adgroup = AdwordsAdGroup.new
                  adgroup.reference_id = row["adgroupid"]
                  adgroup.google_sem_campaign_id = sem_campaign.id
                  adgroup.status = row["agStatus"]
                  adgroup.save
                end

                #Add or Update the Keyword
                keyword = AdwordsKeyword.find_by_reference_id(row["keywordid"])
                if keyword.present?
                  keyword.adwords_ad_group_id = adgroup.id
                  keyword.descriptor = row["keyword"]
                  keyword.dest_url = row["kwDestUrl"]
                  keyword.status = row["kwStatus"]
                  keyword.keyword_type = row["kwType"]
                  keyword.save
                else
                  keyword = AdwordsKeyword.new
                  keyword.reference_id = row["keywordid"]
                  keyword.adwords_ad_group_id = adgroup.id
                  keyword.descriptor = row["keyword"]
                  keyword.dest_url = row["kwDestUrl"]
                  keyword.status = row["kwStatus"]
                  keyword.keyword_type = row["kwType"]
                  keyword.save
                end

                #Add or Update the Ad
                ad = AdwordsAd.find_by_reference_id(row["creativeid"])
                if ad.present?
                  ad.adwords_ad_group_id = adgroup.id
                  ad.status = row["creativeStatus"]
                  ad.dest_url = row["creativeDestUrl"]
                  ad.creative_type = row["creativeType"]
                  ad.headline = row["headline"]
                  ad.desc1 = row["desc1"]
                  ad.desc2 = row["desc2"]
                  ad.dest_url = row["destUrl"]
                  ad.img_name = row["img_name"]
                  ad.hosting_key = row["hosting_key"]
                  ad.preview = row["preview"]
                  ad.vis_url = row["vis_url"]
                else
                  ad = AdwordsAd.new
                  ad.reference_id = row["creativeid"]
                  ad.adwords_ad_group_id = adgroup.id
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
                  ad.save
                end

                #Add the Ad Summary
                adword = AdwordsAdSummary.find_by_adwords_ad_id_and_summary_date(ad.id, date)
                if adword.present?
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
                  adword.save
                else
                  adword = AdwordsAdSummary.new
                  adword.adwords_ad_id = ad.id
                  adword.summary_date = date
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
                  adword.save
                end
              rescue AdWords::Error::Error => e
                puts 'Error Parsing report: %s' % e + " at " + Time.now.to_s
                new_report.result = "Error Occured"
                new_report.job_id = job_id
                new_report.save
              end
            end

            new_report.pulled_on = date.strftime("%m/%d/%Y")
            new_report.result = "Completed"
            new_report.job_id = job_id
          end
          new_report.save
          puts "Completed Report for: " + date.strftime("%m/%d/%Y") + " at " + Time.now.to_s
        rescue AdWords::Error::Error => e
          puts 'Error Updating report: %s' % e + " at " + Time.now.to_s
          new_report.result = "Error Occured"
          new_report.job_id = job_id
          new_report.save
        end
      elsif report_exists.result == "Started" && report_exists.created_at < (Date.today - 1.days)
        SemCampaignReportStatus.delete(report_exists.id)
      end
    end
  end

end
