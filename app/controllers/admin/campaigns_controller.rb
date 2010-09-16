class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
    @timeline = @campaign.campaign_style.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
    @title = @campaign.account.name
    if @campaign.is_sem?
      @chart = GoogleVisualr::Gauge.new
      @chart.add_column('string' , 'Label')
	  @chart.add_column('number' , 'Value')

	  # Add Rows and Values
	  @chart.add_rows(1)
      @chart.set_value(0, 0, 'PPC Spend')
      if @campaign.campaign_style.monthly_budget.present?
        @budget = @campaign.campaign_style.monthly_budget
        @chart.max = @budget
        @chart.set_value(0, 1, @campaign.campaign_style.spend_between(Date.today.beginning_of_month, Date.today.end_of_month))
        @chart.greenFrom = 0
        @chart.greenTo = (@budget * 0.8)
        @chart.yellowFrom = (@budget * 0.8)
        @chart.yellowTo = (@budget * 0.9)
        @chart.redFrom = (@budget * 0.9)
        @chart.redTo = @budget
      else
        @chart.set_value(0, 1, 0)
      end
      @chart.width  = 250
	  @chart.height = 250
    end
    
  end

end
