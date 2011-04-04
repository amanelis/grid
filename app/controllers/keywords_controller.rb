class KeywordsController < ApplicationController
  inherit_resources
  load_and_authorize_resource 
  load_resource :accounts 
  load_resource :channels
  load_resource :campaigns
  
  belongs_to :account
  belongs_to :channel
  belongs_to :campaign
  
  def index
    @keywords = @campaign.campaign_style.keywords
  end
  
  def show
    datepicker channel_campaign_keyword_path(@account, @channel, @campaign, @keyword)
    #@start_date = Date.today - 1.month
    #@end_date   = Date.today - 1.month
    
    if @campaign.is_seo?
      @rankings = @keyword.keyword_rankings.sort { |a,b| b.created_at <=> a.created_at }
  
      @daily_keyword_ranking_graph = HighChart.new('graph') do |f|
        f.title(:text => false)  
        f.y_axis({:title=> {:text=> 'Search Engine Rank'}, :min => 0, :labels=>{:align=>'right'} })
        f.x_axis(:type => 'datetime', :tickInterval => 7 * 24 * 3600 * 1000, :dateTimeLabelFormats =>{:year => "%Y", :month => "%b %y", :week => "%b %e", :day => "%b %e"})
        f.legend(:enabled => true)
    
        f.chart(:defaultSeriesType => 'spline', :backgroundColor => false, :zoomType => "x")
        f.series(:name=> 'Google Ranking', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_google_ranking_between(@start_date, @end_date))
        f.series(:name=> 'Yahoo Ranking', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_yahoo_ranking_between(@start_date, @end_date))
        #f.series(:name=> 'Bing Ranking', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_bing_ranking_between(@start_date, @end_date))
      end
    end
    
  end
  
end
