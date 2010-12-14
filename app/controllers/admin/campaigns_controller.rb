class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
    Time.zone = @campaign.account.time_zone
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
        @spend = (@campaign.campaign_style.spend_between(Date.today.beginning_of_month, Date.today.end_of_month) * 100).round.to_f / 100
        @chart.max = @budget
        @chart.set_value(0, 1, @spend)
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
    if params[:daterange].blank?
      @start_date = Date.yesterday - 1.week
      @end_date = Date.yesterday

      respond_to do |format|
        format.html # show.html.erb
      end
    else
      # Parse the date the GET request has received
      dates = params[:daterange].split(' - ')

      begin
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue Exception
        @start_date = Date.yesterday - 1.week
        @end_date = Date.yesterday
      end

      respond_to do |format|
        format.html # show.html.erb
      end
    end
  end
  
  def update
    @campaign = Campaign.find(params[:id])
    
    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id)
    end
    
    redirect_to admin_campaign_path(@campaign)
  end
  
  def lead_matrix
    if params[:minutepicker].blank?
      @minutes_selected = 2
    else
      begin
        #Default it to a number!
        @minutes_selected = (params[:minutepicker].to_i if Float(params[:minutepicker]) rescue 2)
      rescue Exception
        @minutes_selected = 2
      end
    end
    
    if params[:daterangepicker].blank?
      @campaign = Campaign.find(params[:id])
      Time.zone = @campaign.account.time_zone
       
      @date_selected = Date.yesterday

      respond_to do |format|
        format.html # show.html.erb
      end
    else
       @campaign = Campaign.find(params[:id])
        Time.zone = @campaign.account.time_zone
      # Parse the date the GET request has received
      dates = params[:daterangepicker].split(' - ')

      begin
        @date_selected = Date.parse(dates[0])
      rescue Exception
        @date_selected = Date.yesterday
      end
    end
  end
  
  def create
    @campaign = Campaign.new
    create if request.post?
  end

end
