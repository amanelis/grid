class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
    @timeline = @campaign.campaign_style.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
    @title = @campaign.account.name
    @chart = GoogleVisualr::Gauge.new
    @chart.add_column('string' , 'Label')
	@chart.add_column('number' , 'Value')

	# Add Rows and Values
	@chart.add_rows(1)
    @chart.set_value(0, 0, 'PPC Spend')
    @chart.set_value(0, 1, 80)
	@chart.width  = 350
	@chart.height = 200
    
  end

end
