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
    #cookies[:start_date] = Date.today - 1.month
    #cookies[:end_date]   = Date.today - 1.month

    if @campaign.is_seo?
      @rankings = @keyword.keyword_rankings.sort { |a,b| b.created_at <=> a.created_at }

      @daily_keyword_ranking_graph = HighChart.new('graph') do |f|
        f.title(:text => false)
        f.y_axis(:reversed => true, :min => 1, :max => 100, :title=> false, :startOnTick => true, :labels=> {:align=>'right'}, :plotBands =>[{ :color => "rgba(68, 170, 213, 0.3)", :from => 1, :to => 10, :label =>{:text =>"First Page"}}, { :color => "rgba(68, 170, 213, 0.1)", :from => 10, :to => 20, :label =>{:text =>"Second Page"}}])
        f.x_axis(:type => 'datetime', :maxZoom => 14 * 24 * 3600000, :dateTimeLabelFormats =>{:year => "%Y", :month => "%b %y", :week => "%b %e", :day => "%b %e"})
        f.legend(:enabled => true)
        f.plot_options({:marker=> {:enabled=> false}})

        f.chart(:defaultSeriesType => 'spline', :backgroundColor => false, :zoomType => "x")
        f.series(:name=> 'Google Ranking', :marker => {:enabled => false, :states => {:hover => {:enabled => true, :symbol => "circle", :radius => "5", :lineWidth => "1"}}}, :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => cookies[:start_date].to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_google_ranking_between(cookies[:start_date], cookies[:end_date]))
        f.series(:name=> 'Yahoo Ranking', :marker => {:enabled => false, :states => {:hover => {:enabled => true, :symbol => "circle", :radius => "5", :lineWidth => "1"}}}, :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => cookies[:start_date].to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_yahoo_ranking_between(cookies[:start_date], cookies[:end_date]))
        #f.series(:name=> 'Bing Ranking', :marker => {:enabled => false, :states => {:hover => {:enabled => true, :symbol => "circle", :radius => "5", :lineWidth => "1"}}}, :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => cookies[:start_date].to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => @keyword.daily_most_recent_bing_ranking_between(cookies[:start_date], cookies[:end_date]))
      end
    end

  end

end
