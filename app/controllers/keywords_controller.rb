class KeywordsController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  
  def index
      @campaign = Campaign.find(params[:id])
      @keywords = @campaign.campaign_style.keywords 
  end
  
  def show
    @rankings = @keyword.keyword_rankings.sort { |a,b| b.created_at <=> a.created_at }
    
    @daily_keyword_ranking_graph = HighChart.new('graph') do |f|
      f.title(:text => false)  
      f.y_axis({:title=> false, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:type => 'datetime', :tickInterval => 7 * 24 * 3600 * 1000, :dateTimeLabelFormats =>{:week => "%b %e"})
      f.legend(:enabled => false)
      
      f.chart(:defaultSeriesType => 'area', :backgroundColor => false)
      f.series(:name=> 'Leads', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => ([4,5,6]))
    end
  end
  
end
