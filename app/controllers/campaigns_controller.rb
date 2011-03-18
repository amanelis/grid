class CampaignsController < ApplicationController
  inherit_resources
  load_resource :except => [:create]
  load_resource :accounts 
  load_resource :channels
  
  belongs_to :account
  belongs_to :channel
  
  def new
    authorize! :manipulate_account, @account
    no_layout
  end
  
  def create
    authorize! :manipulate_account, @account
    if @channel.channel_type == "basic"
      bc = BasicCampaign.new
      bc.account = @account
      bc.channel = @channel
      bc.name    = params[:campaign][:name]
      bc.save
      
      bc.campaign.status = "Active"
      bc.campaign.save
      #number = bc.campaign.create_twilio_number(params[:campaign][:area_code], params[:campaign][:name], params[:campaign][:forward_to])
      #form = bc.campaign.create_contact_form('', params[:campaign][:forwarding_email])
      flash[:notice] = "Good job, you just created a campaign!"
      redirect_to channel_campaign_path(@account, @channel, bc.campaign)
    elsif @channel.channel_type == "sem"
      # Creating a SEM 
    elsif @channel.channel_type == "seo"
      # Creating a SEO
    end
  end

  def show
    authorize! :read, @campaign
    datepicker channel_campaign_path(@account, @channel, @campaign)
    
    @daily_keyword_ranking_graph = HighChart.new('graph') do |f|
      f.title(:text => false)  
      f.y_axis({:title=> false, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:type => 'datetime', :tickInterval => 7 * 24 * 3600 * 1000, :dateTimeLabelFormats =>{:week => "%b %e"})
      f.legend(:enabled => false)
      
      f.chart(:defaultSeriesType => 'area', :backgroundColor => false)
      f.series(:name=> 'Leads', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => (6))
    end
  end
  
  def edit
    authorize! :manipulate_campaign, @campaign
    render :layout => false
  end
  
  def update
    authorize! :manipulate_campaign, @campaign
    @campaign.update_attributes(params[:campaign])
    flash[:notice] = "Alright, that CAMPAIGN was updated."
    redirect_to account_path(@account)
  end
  
  # We want to change active status not destroy the actual campaign
  def destroy
    authorize! :manipulate_campaign, @campaign
    @campaign.update_attributes!(:status => "Inactive")
    flash.now[:error] = "Ooops, there was an error deleting that CAMPAIGN, you might want to try again."
    redirect_to account_path(@account)
  end
  
  def lead_matrix
    @campaign = Campaign.find(params[:id])
    authorize! :lead_matrix, @campaign
    Time.zone = @campaign.account.time_zone
    if params[:minutepicker].blank?
      @minutes_selected = 2
    else
      begin
        @minutes_selected = (params[:minutepicker].to_i if Float(params[:minutepicker]) rescue 2)
      rescue Exception
        @minutes_selected = 2
      end
    end
    
    if params[:datepicker].blank? 
      @date_selected = Date.yesterday
    else
      @campaign = Campaign.find(params[:id])
      Time.zone = @campaign.account.time_zone
      begin
        dates = params[:datepicker].split("/")
        @date_selected = Date.new(dates[2].to_i, dates[0].to_i, dates[1].to_i)
      rescue Exception
        @date_selected = Date.yesterday
      end
    end
  end
  
  def create_new_campaign_contact_form
    authorize! :manipulate_campaign, @campaign
    @campaign = Campaign.find(params[:id])
    if @campaign.present?
      @form_text = @campaign.create_contact_form(params[:description], params[:return_url], params[:forwarding_email], params[:forwarding_bcc_email], params[:custom1_text], params[:custom2_text], params[:custom3_text], params[:custom4_text], params[:need_name], params[:need_address], params[:need_phone], params[:need_email], params[:work_category], params[:work_description], params[:date_requested], params[:time_requested], params[:other_information])
      @form = @campaign.contact_forms.last
    end
  end
  
end
