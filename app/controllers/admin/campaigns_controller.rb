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
        @chart.set_value(0, @campaign.campaign_style.monthly_budget, @campaign.campaign_style.spend_between(Date.today.beginning_of_month, Date.today.end_of_month))
      else
        @chart.set_value(0, 1, 60)
      end
	  @chart.width  = 250
	  @chart.height = 175
    end
    
  end

end
