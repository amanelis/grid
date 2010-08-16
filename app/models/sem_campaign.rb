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
        sem_campaign.create_sem_campaign_report(pull_date, 'Campaign')
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
        sem_campaign.create_sem_campaign_report(pull_date, 'Ad')
        span -= 1
      end
    end
  end

  def create_sem_campaign_report(date, report_type = 'Campaign')
    campaign_array = self.google_sem_campaigns.collect { |google_sem_campaign| google_sem_campaign.adwords_campaign.reference_id }
    report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ? AND sem_campaign_id = ?', date.strftime('%m/%d/%Y'), report_type, self.id])
    job_id = 0
    new_report = SemCampaignReportStatus.new
    new_report.result = 'Started'

    if report_type == 'Campaign'
      if report_exists == nil && campaign_array.present?
        puts 'Started Report for: ' + date.strftime('%m/%d/%Y') + ' at ' + Time.now.to_s
        new_report.pulled_on = date.strftime('%m/%d/%Y')
        new_report.report_type = 'Campaign'
        new_report.sem_campaign_id = self.id
        new_report.save
        begin
          adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => self.developer_token, 'applicationToken' => self.application_token, 'useragent' => self.user_agent, 'password' => self.password, 'email' => self.email, 'clientEmail' => self.client_email, 'environment' => 'PRODUCTION', }))
          report_name = campaign.name + ': ' + date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          report_srv = adwords.get_service('Report', 13)
          job = report_srv.module::DefinedReportJob.new
          job.selectedReportType = 'Campaign'
          job.aggregationTypes = 'Summary'
          job.name = report_name
          job.selectedColumns = %w{  Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank  }
          job.startDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.endDay = date.year.to_s + '-' + date.month.to_s + '-' + date.day.to_s
          job.crossClient = true
          job.campaigns = campaign_array

          report_srv.validateReportJob(job)

          job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
          #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
          sleep(15)
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))

          rows = report.xpath('//row')
          if rows.size < (job.campaigns.size + 5)
            new_report.result = 'Completed'
            rows.each do |row|
              begin
                #Add or Update the Client
                client = AdwordsClient.find_or_create_by_name(:name => row['acctname'],
                                                              :businessName => row['businessName'],
                                                              :timezone => row['timezone'],
                                                              :reference_id => row['customerid'],
                                                              :account_id => self.campaign.account.id)
                client.save

                #Add or Update the Campaign
                adwords_campaign = AdwordsCampaign.find_or_create_by_reference_id(:reference_id => row['campaignid'],
                                                                                  :google_sem_campaign_id => self.google_sem_campaigns.select { |google_sem_campaign| google_sem_campaign.google_campaign_id == row['campaignid'] },
                                                                                  :name => row['campaign'],
                                                                                  :campStatus => row['campStatus'],
                                                                                  :campaign_type => row['adwordsType'])
                adwords_campaign.save

                adword = AdwordsCampaignSummary.find_or_create_by_adwords_campaign_id_and_report_date(:adwords_campaign_id => adwords_campaign.id,
                                                                                                      :report_date => date,
                                                                                                      :conv => row['conv'],
                                                                                                      :cost => row['cost'],
                                                                                                      :status => row['campStatus'],
                                                                                                      :invalid_clicks => row['invalidClicks'],
                                                                                                      :total_interactions => row['totalInteractions'],
                                                                                                      :budget => row['budget'],
                                                                                                      :imps => row['imps'],
                                                                                                      :pos => row['pos'],
                                                                                                      :cpc => row['cpc'],
                                                                                                      :cpm => row['cpm'],
                                                                                                      :ctr => row['ctr'],
                                                                                                      :exact_match_imp_share => row['exactMatchImpShare'],
                                                                                                      :imp_share => row['impShare'],
                                                                                                      :lost_imp_share_budget => row['lostImpShareBudget'],
                                                                                                      :lost_imp_share_rank => row['lostImpShareRank'],
                                                                                                      :clicks => row['clicks'])
                adword.save
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
            job.selectedColumns = %w{  Campaign CampaignId AdWordsType AveragePosition CPC CPM CTR CampaignStatus Clicks Conversions Cost ExternalCustomerId CustomerName CustomerTimeZone DailyBudget Impressions exactMatchImpShare impShare lostImpShareBudget lostImpShareRank  }
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
                client = AdwordsClient.find_or_create_by_name(:name => row['acctname'],
                                                              :businessName => row['businessName'],
                                                              :timezone => row['timezone'],
                                                              :reference_id => row['customerid'],
                                                              :account_id => self.campaign.account.id)
                client.save

                #Add or Update the Campaign
                adwords_campaign = AdwordsCampaign.find_or_create_by_reference_id(:reference_id => row['campaignid'],
                                                                                  :google_sem_campaign_id => self.google_sem_campaigns.select { |google_sem_campaign| google_sem_campaign.google_campaign_id == row['campaignid'] },
                                                                                  :name => row['campaign'],
                                                                                  :campStatus => row['campStatus'],
                                                                                  :campaign_type => row['adwordsType'])
                adwords_campaign.save

                adword = AdwordsCampaignSummary.find_or_create_by_adwords_campaign_id_and_report_date(:adwords_campaign_id => adwords_campaign.id,
                                                                                                      :report_date => date,
                                                                                                      :conv => row['conv'],
                                                                                                      :cost => row['cost'],
                                                                                                      :status => row['campStatus'],
                                                                                                      :invalid_clicks => row['invalidClicks'],
                                                                                                      :total_interactions => row['totalInteractions'],
                                                                                                      :budget => row['budget'],
                                                                                                      :imps => row['imps'],
                                                                                                      :pos => row['pos'],
                                                                                                      :cpc => row['cpc'],
                                                                                                      :cpm => row['cpm'],
                                                                                                      :ctr => row['ctr'],
                                                                                                      :exact_match_imp_share => row['exactMatchImpShare'],
                                                                                                      :imp_share => row['impShare'],
                                                                                                      :lost_imp_share_budget => row['lostImpShareBudget'],
                                                                                                      :lost_imp_share_rank => row['lostImpShareRank'],
                                                                                                      :clicks => row['clicks'])
                adword.save
              rescue
                report_exists.result = 'Error Occured'
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
          report_exists.job_id = report_exists.job_id
          report_exists.save
        end
      elsif report_exists.result == 'Started' && report_exists.created_at < (Date.today - 1.days)
        SemCampaignReportStatus.delete(report_exists.id)
      end
      #PULL THE AD REPORT
    elsif report_type == 'Ad'
      report_exists = SemCampaignReportStatus.first(:conditions => ['pulled_on = ? AND report_type= ?', date.strftime("%m/%d/%Y"), report_type])
      job_id = 0
      new_report = SemCampaignReportStatus.new

      if report_exists == nil
        new_report.pulled_on = date.strftime("%m/%d/%Y")
        new_report.result = "Started"
        new_report.report_type = "Ad"
        new_report.save
        puts "Started Report for: " + date.strftime("%m/%d/%Y") + " at " + Time.now.to_s

        adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => 'HC3GEwJ4LqgyVNeNTenIVw', 'applicationToken' => '-o8E21xqBmVx7CkQ5TfAag', 'useragent' => 'Biz Search Local', 'password' => 'brayden11', 'email' => 'bizsearchlocal.jon@gmail.com', 'clientEmail' => 'bizsearchlocal.jon@gmail.com', 'environment' => 'PRODUCTION', }))
        report_name = "Ad- " + self.name + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        report_srv = adwords.get_service('Report', 13)
        job = report_srv.module::DefinedReportJob.new
        job.selectedReportType = 'Creative'
        job.aggregationTypes = 'Summary'
        job.name = report_name
        job.selectedColumns = %w{ AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl  }
        job.startDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        job.endDay = date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
        job.crossClient = true
        job.campaigns = campaign_array

        report_srv.validateReportJob(job)

        job_id = report_srv.scheduleReportJob(job).scheduleReportJobReturn
        #puts 'Scheduled report with id %d. Now sleeping %d seconds.' %[job_id, sleep_interval]
        sleep(20)
        begin
          report = Nokogiri::XML(report_srv.downloadXmlReport(job_id))
          rows = report.xpath("//row")
          if rows.size < (job.campaigns.size + 5)
            new_report.result = 'Completed'
            rows.each do |row|
              #Add or Update the Client
              client = AdwordsClient.find_or_create_by_acctname_and_account_id(:name => row["acctname"],
                                                                               :account_id => self.campaign.account.id,
                                                                               :businessName => row["businessName"],
                                                                               :timezone => row["timezone"],
                                                                               :reference_id => row["customerid"])

              #Add or Update the Campaign
              adwords_campaign = AdwordsCampaign.find_or_create_by_reference_id(:reference_id => row['campaignid'],
                                                                                :google_sem_campaign_id => self.google_sem_campaigns.select { |google_sem_campaign| google_sem_campaign.google_campaign_id == row['campaignid'] },
                                                                                :name => row['campaign'],
                                                                                :campStatus => row['campStatus'],
                                                                                :campaign_type => row['adwordsType'])
              adwords_campaign.save

              #Add or Update the Ad Group
              adgroup = AdwordsAdGroup.find_or_create_by_reference_id(:reference_id => row["adgroupid"],
                                                                      ########FIXXXX                                                     :adwords_campaign_id => self.id,
                                                                      :status => row["agStatus"])

              #Add or Update the Keyword
              keyword = AdwordsKeyword.find_or_create_by_reference_id(:reference_id => row["keywordid"],
                                                                      :adwords_ad_group_id => adgroup.id,
                                                                      :descriptor => row["keyword"],
                                                                      :dest_url => row["kwDestUrl"],
                                                                      :status => row["kwStatus"],
                                                                      :keyword_type => row["kwType"])
              #Add or Update the Ad
              ad = AdwordsAd.find_or_create_by_reference_id(:reference_id => row["creativeid"],
                                                            :adwords_ad_group_id => adgroup.id,
                                                            :status => row["creativeStatus"],
                                                            :dest_url => row["creativeDestUrl"],
                                                            :creative_type => row["creativeType"],
                                                            :headline => row["headline"],
                                                            :desc1 => row["desc1"],
                                                            :desc2 => row["desc2"],
                                                            :destUrl => row["destUrl"],
                                                            :img_name => row["imgCreativeName"],
                                                            :hosting_key => row["hostingKey"],
                                                            :preview => row["preview"],
                                                            :vis_url => row["creativeVisUrl"])
              #Add the Ad Summary
              adword = AdwordsAdSummary.find_or_create_by_adwords_ad_id_and_adwords_keyword_id_and_summaryDate(:adwords_ad_id => ad.id,
                                                                                                               :adwords_keyword_id => keyword.id,
                                                                                                               :summaryDate => date,
                                                                                                               :conv => row["conv"],
                                                                                                               :cost => row["cost"],
                                                                                                               :budget => row["budget"],
                                                                                                               :default_conv => row["defaultConv"],
                                                                                                               :default_conv_value => row["defaultConvValue"],
                                                                                                               :first_page_cpc => row["firstPageCpc"],
                                                                                                               :imps => row["imps"],
                                                                                                               :leads => row["leads"],
                                                                                                               :lead_value => row["leadValue"],
                                                                                                               :max_content_cpc => row["maxContentCpc"],
                                                                                                               :max_cpc => row["maxCpc"],
                                                                                                               :max_cpm => row["maxCpm"],
                                                                                                               :page_views => row["pageviews"],
                                                                                                               :page_view_value => row["pageviewValue"],
                                                                                                               :ag_max_cpa => row["agMaxCpa"],
                                                                                                               :avg_conv_value => row["avgConvValue"],
                                                                                                               :pos => row["pos"],
                                                                                                               :avg_percent_played => row["avgPercentPlayed"],
                                                                                                               :bottom_position => row["bottomPosition"],
                                                                                                               :cpc => row["cpc"],
                                                                                                               :cpm => row["cpm"],
                                                                                                               :ctr => row["ctr"],
                                                                                                               :quality_score => row["qualityScore"],
                                                                                                               :purchases => row["purchases"],
                                                                                                               :purchase_value => row["purchaseValue"],
                                                                                                               :sign_ups => row["signups"],
                                                                                                               :sign_up_value => row["signupValue"],
                                                                                                               :top_position => row["topPosition"],
                                                                                                               :conv_value => row["convValue"],
                                                                                                               :transactions => row["transactions"],
                                                                                                               :conv_vpc => row["convVpc"],
                                                                                                               :value_cost_ratio => row["valueCostRatio"],
                                                                                                               :video_playbacks => row["videoPlaybacks"],
                                                                                                               :video_playbacks_through_100_percent => ["videoPlaybacksThrough100Percent"],
                                                                                                               :video_playbacks_through_50_percent => row["videoPlaybacksThrough50Percent"],
                                                                                                               :video_playbacks_through_25_percent => row["videoPlaybacksThrough25Percent"],
                                                                                                               :video_playbacks_through_75_percent => row["videoPlaybacksThrough75Percent"],
                                                                                                               :video_skips => row["videoSkips"],
                                                                                                               :keyword_min_cpc => row["keywordMinCpc"],
                                                                                                               :cpt => row["cpt"],
                                                                                                               :cost_per_video_playback => row["costPerVideoPlayback"],
                                                                                                               :conv_rate => row["convRate"],
                                                                                                               :cost_per_conv => row["costPerConv"],
                                                                                                               :clicks => row["clicks"])
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
        adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => 'HC3GEwJ4LqgyVNeNTenIVw', 'applicationToken' => '-o8E21xqBmVx7CkQ5TfAag', 'useragent' => 'Biz Search Local', 'password' => 'brayden11', 'email' => 'bizsearchlocal.jon@gmail.com', 'clientEmail' => 'bizsearchlocal.jon@gmail.com', 'environment' => 'PRODUCTION', }))

        report_srv = adwords.get_service('Report', 13)
        job_id = report_exists.job_id
        if job_id == nil
          adwords = AdWords::API.new(AdWords::AdWordsCredentials.new({'developerToken' => 'HC3GEwJ4LqgyVNeNTenIVw', 'applicationToken' => '-o8E21xqBmVx7CkQ5TfAag', 'useragent' => 'Biz Search Local', 'password' => 'brayden11', 'email' => 'bizsearchlocal.jon@gmail.com', 'clientEmail' => 'bizsearchlocal.jon@gmail.com', 'environment' => 'PRODUCTION', }))
          report_name = "Ad- " + self.name + date.year.to_s + "-" + date.month.to_s + "-" + date.day.to_s
          report_srv = adwords.get_service('Report', 13)
          job = report_srv.module::DefinedReportJob.new
          job.selectedReportType = 'Creative'
          job.aggregationTypes = 'Summary'
          job.name = report_name
          job.selectedColumns = %w{ AdWordsType SignupCount CostPerTransaction CostPerVideoPlayback ConversionRate CostPerConverstion CostPerVideoPlayback KeywordStatus KeywordTypeDisplay CreativeId AdGroup AdGroupId AdGroupMaxCpa AdGroupStatus AdStatus AverageConversionValue AveragePosition AvgPercentOfVideoPlayed BottomPosition BusinessAddress BusinessName CPC CPM CTR Campaign CampaignId CampaignStatus Clicks Conversions Cost DescriptionLine1 DescriptionLine2 DescriptionLine3 DestinationURL ExternalCustomerId KeywordMinCPC CreativeDestUrl CreativeType CustomerName CustomerTimeZone DailyBudget DefaultCount DefaultValue FirstPageCpc ImageAdName ImageHostingKey Impressions Keyword KeywordId KeywordDestUrlDisplay LeadCount LeadValue MaxContentCPC MaximumCPC MaximumCPM PageViewCount PageViewValue PhoneNo PreferredCPC PreferredCPM Preview QualityScore SalesCount SalesValue SignupValue TopPosition TotalConversionValue Transactions ValuePerClick ValuePerCost VideoPlaybackRate VideoPlaybacks VideoPlaybacksThrough100Percent VideoPlaybacksThrough75Percent VideoPlaybacksThrough50Percent VideoPlaybacksThrough25Percent VideoSkips VisibleUrl  }
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
              #Add or Update the Client
              client = AdwordsClient.find_or_create_by_acctname_and_account_id(:name => row["acctname"],
                                                                               :account_id => self.campaign.account.id,
                                                                               :businessName => row["businessName"],
                                                                               :timezone => row["timezone"],
                                                                               :reference_id => row["customerid"])

              #Add or Update the Campaign
              adwords_campaign = AdwordsCampaign.find_or_create_by_reference_id(:reference_id => row['campaignid'],
                                                                                :google_sem_campaign_id => self.google_sem_campaigns.select { |google_sem_campaign| google_sem_campaign.google_campaign_id == row['campaignid'] },
                                                                                :name => row['campaign'],
                                                                                :campStatus => row['campStatus'],
                                                                                :campaign_type => row['adwordsType'])
              adwords_campaign.save

              #Add or Update the Ad Group
              adgroup = AdwordsAdGroup.find_or_create_by_reference_id(:reference_id => row["adgroupid"],
                                                                      ########FIXXXX                                                     :adwords_campaign_id => self.id,
                                                                      :status => row["agStatus"])

              #Add or Update the Keyword
              keyword = AdwordsKeyword.find_or_create_by_reference_id(:reference_id => row["keywordid"],
                                                                      :adwords_ad_group_id => adgroup.id,
                                                                      :descriptor => row["keyword"],
                                                                      :dest_url => row["kwDestUrl"],
                                                                      :status => row["kwStatus"],
                                                                      :keyword_type => row["kwType"])
              #Add or Update the Ad
              ad = AdwordsAd.find_or_create_by_reference_id(:reference_id => row["creativeid"],
                                                            :adwords_ad_group_id => adgroup.id,
                                                            :status => row["creativeStatus"],
                                                            :dest_url => row["creativeDestUrl"],
                                                            :creative_type => row["creativeType"],
                                                            :headline => row["headline"],
                                                            :desc1 => row["desc1"],
                                                            :desc2 => row["desc2"],
                                                            :destUrl => row["destUrl"],
                                                            :img_name => row["imgCreativeName"],
                                                            :hosting_key => row["hostingKey"],
                                                            :preview => row["preview"],
                                                            :vis_url => row["creativeVisUrl"])
              #Add the Ad Summary
              adword = AdwordsAdSummary.find_or_create_by_adwords_ad_id_and_adwords_keyword_id_and_summaryDate(:adwords_ad_id => ad.id,
                                                                                                               :adwords_keyword_id => keyword.id,
                                                                                                               :summaryDate => date,
                                                                                                               :conv => row["conv"],
                                                                                                               :cost => row["cost"],
                                                                                                               :budget => row["budget"],
                                                                                                               :default_conv => row["defaultConv"],
                                                                                                               :default_conv_value => row["defaultConvValue"],
                                                                                                               :first_page_cpc => row["firstPageCpc"],
                                                                                                               :imps => row["imps"],
                                                                                                               :leads => row["leads"],
                                                                                                               :lead_value => row["leadValue"],
                                                                                                               :max_content_cpc => row["maxContentCpc"],
                                                                                                               :max_cpc => row["maxCpc"],
                                                                                                               :max_cpm => row["maxCpm"],
                                                                                                               :page_views => row["pageviews"],
                                                                                                               :page_view_value => row["pageviewValue"],
                                                                                                               :ag_max_cpa => row["agMaxCpa"],
                                                                                                               :avg_conv_value => row["avgConvValue"],
                                                                                                               :pos => row["pos"],
                                                                                                               :avg_percent_played => row["avgPercentPlayed"],
                                                                                                               :bottom_position => row["bottomPosition"],
                                                                                                               :cpc => row["cpc"],
                                                                                                               :cpm => row["cpm"],
                                                                                                               :ctr => row["ctr"],
                                                                                                               :quality_score => row["qualityScore"],
                                                                                                               :purchases => row["purchases"],
                                                                                                               :purchase_value => row["purchaseValue"],
                                                                                                               :sign_ups => row["signups"],
                                                                                                               :sign_up_value => row["signupValue"],
                                                                                                               :top_position => row["topPosition"],
                                                                                                               :conv_value => row["convValue"],
                                                                                                               :transactions => row["transactions"],
                                                                                                               :conv_vpc => row["convVpc"],
                                                                                                               :value_cost_ratio => row["valueCostRatio"],
                                                                                                               :video_playbacks => row["videoPlaybacks"],
                                                                                                               :video_playbacks_through_100_percent => ["videoPlaybacksThrough100Percent"],
                                                                                                               :video_playbacks_through_50_percent => row["videoPlaybacksThrough50Percent"],
                                                                                                               :video_playbacks_through_25_percent => row["videoPlaybacksThrough25Percent"],
                                                                                                               :video_playbacks_through_75_percent => row["videoPlaybacksThrough75Percent"],
                                                                                                               :video_skips => row["videoSkips"],
                                                                                                               :keyword_min_cpc => row["keywordMinCpc"],
                                                                                                               :cpt => row["cpt"],
                                                                                                               :cost_per_video_playback => row["costPerVideoPlayback"],
                                                                                                               :conv_rate => row["convRate"],
                                                                                                               :cost_per_conv => row["costPerConv"],
                                                                                                               :clicks => row["clicks"])
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
        AdwordsReportDate.delete(report_exists.id)
      end
    end
  end

end
