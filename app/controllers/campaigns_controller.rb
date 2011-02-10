class CampaignsController < ApplicationController
  inherit_resources
  load_and_authorize_resource :account
  load_and_authorize_resource :campaign, :through => :account  
  belongs_to :account
  before_filter :load_time_zone, :only  => [:show]
  
  def new
    authorize! :manipulate_campaign, @account
    @industries = Industry.all.collect {|a| a.name}.sort!
    @flavors = Campaign.flavors
    if @campaign.present?
      @campaign = @account.campaigns.build
    end
  end
  
  def create
    authorize! :manipulate_campaign, @account
    if @account.present?
      if params[:flavor].include? 'SEM'
        new_campaign = SemCampaign.new
        new_campaign.flavor = params[:flavor]
      elsif params[:flavor].include? 'SEO'
        new_campaign = SeoCampaign.new 
        new_campaign.flavor = params[:flavor]
      elsif params[:flavor].include? 'Maps'
        new_campaign = MapsCampaign.new 
        new_campaign.flavor = params[:flavor]
      else
        new_campaign = OtherCampaign.new
        new_campaign.flavor = params[:flavor]
      end
      
      new_campaign.account = @account
      new_campaign.status = 'Active'
      new_campaign.save
      new_campaign.name = params[:name]
      new_campaign.campaign.industry = (params[:industry])
      #Needs to be Uncommented when we roll out
      #new_campaign.campaign.url = (params[:url])
      #new_campaign.campaign.forwarding_number =  params[:forwarding_number]
      #new_campaign.campaign.area_code = (params[:area_code])
      new_campaign.save
      redirect_to "/campaigns/#{new_campaign.campaign.id}"
    end  
  end

  def show    
    datepicker campaign_path(resource)
  end
  
  def update
    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id)
    end
    redirect_to campaign_path(@campaign)
  end
  
  def lead_matrix
    @campaign = Campaign.find(params[:id])
    authorize! :lead_matrix, @campaign
    Time.zone = @campaign.account.time_zone
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

  def new_campaign_contact_form
  end
  
  def create_new_campaign_contact_form
    @campaign = Campaign.find(params[:id])
    if @campaign.present?
      @form_text = @campaign.create_contact_form(params[:description], params[:return_url], params[:forwarding_email], params[:forwarding_bcc_email], params[:custom1_text], params[:custom2_text], params[:custom3_text], params[:custom4_text], params[:need_name], params[:need_address], params[:need_phone], params[:need_email], params[:work_category], params[:work_description], params[:date_requested], params[:time_requested], params[:other_information])
      @form = @campaign.contact_forms.last
    end
  end
  
end
