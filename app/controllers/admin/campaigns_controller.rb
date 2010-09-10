class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
    @timeline = @campaign.campaign_style.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
    @title = @campaign.account.name
    @chart = GoogleVisualr::AreaChart.new
    @chart.add_column('string', 'Year' )
	@chart.add_column('number', 'Sales')
	@chart.add_column('number', 'Expenses')

	# Add Rows and Values
	@chart.add_rows(4)
    @chart.set_value(0, 0, '2004')
    @chart.set_value(0, 1, 1000)
	@chart.set_value(0, 2, 400)
	@chart.set_value(1, 0, '2005')
	@chart.set_value(1, 1, 1170)
	@chart.set_value(1, 2, 460)
	@chart.set_value(2, 0, '2006')
	@chart.set_value(2, 1, 1500)
	@chart.set_value(2, 2, 660)
	@chart.set_value(3, 0, '2007')
	@chart.set_value(3, 1, 1030)
	@chart.set_value(3, 2, 540)
    @chart.width  = 400
	@chart.height = 240
  end

end
