class CampaignsController < ApplicationController
  load_and_authorize_resource

  def show  
    @campaign = Campaign.find(params[:id])
    authorize! :read, @campaign
    
    Time.zone = @campaign.account.time_zone
    @timeline = @campaign.campaign_style.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
    @title = @campaign.account.name
    @date_range = ''
    
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
      @start_date = Date.today.beginning_of_month
      @end_date = Date.yesterday
      
      respond_to do |format|
        format.html # show.html.erb
      end
    else
      # Parse the date the GET request has received
      dates = params[:daterange].split(' to ') || params[:daterange].split(' - ')
      @date_range = params[:daterange]
      
      begin 
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue
        @start_date = Date.today.beginning_of_month
        @end_date = Date.yesterday
        flash[:error] = "Your date was incorrect, we set it back to #{@start_date} to #{@end_date}"
        redirect_to campaign_path(params[:id])
      end
      
    end
    
  end
  
  def update
    @campaign = Campaign.find(params[:id])
    
    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id)
    end
    
    redirect_to campaign_path(@campaign)
  end
  
  def lead_matrix
    @campaign = Campaign.find(params[:id])
    authorize! :lead_matrix, @campaign
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
    
    if params[:datepicker].blank?
      @campaign = Campaign.find(params[:id])
      Time.zone = @campaign.account.time_zone
       
      @date_selected = Date.yesterday

      respond_to do |format|
        format.html # show.html.erb
      end
    else
      @campaign = Campaign.find(params[:id])
      Time.zone = @campaign.account.time_zone
      begin
        #@date_selected = Date.strptime(params[:datepicker], '%Y/%d/%m')
        dates = params[:datepicker].split("/")
        @date_selected = Date.new(dates[2].to_i, dates[0].to_i, dates[1].to_i)
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
