class CampaignsController < ApplicationController
  inherit_resources
  load_resource :campaign, :through => :account
  load_and_authorize_resource :account
  load_and_authorize_resource :campaign, :through => :account, :except => [:new, :create]
  belongs_to :account
  before_filter :load_time_zone, :only  => [:show]
  
  def new
    authorize! :manipulate_account, @account
    @industries = Industry.all.collect {|a| a.name}.sort!.insert(0, 'Select...')
    @flavors = Campaign.flavors.select {|a| !a.downcase.include? "seo"}.select {|a|  !a.downcase.include? "sem"}.select {|a| !a.downcase.include? 'maps'}.sort!.insert(0, 'Select...')
    if @campaign.present?
      @campaign = @account.campaigns.build
    end
  end
  
  def create
    authorize! :manipulate_account, @account
    flash[:error] = "You must select a campaign type" if params[:flavor] == 'Select...'
    flash[:error] = "You must select an Industry" if params[:industry] == 'Select...'
    flash[:error] = "Sorry, but there are no available numbers for the #{params[:area_code]} area code" if PhoneNumber.available_numbers(params[:area_code]).blank?
    redirect_to request.referer if flash[:error].present?
    if @account.present?
      if @account.campaigns.find_by_name(params[:name]).present?
        flash[:error] = "Sorry, but a campaign with the name #{params[:name]} already exists on this account"
        redirect_to request.referer
      else
        campaign = @account.create_campaign(params[:flavor], params[:name])
        campaign.industry = params[:industry]
        #campaign.url = url
        #campaign.forwarding_number =  params[:forwarding_number]
        #campaign.area_code = params[:area_code]
        #campaign.save
        redirect_to account_campaign_path(@account.id, campaign.id, :phone_number => PhoneNumber.first)
      end
    end 
  end

  def show   
    datepicker campaign_path(@campaign)
    @phone_number = PhoneNumber.find(params[:phone_number]) unless params[:phone_number].blank?
    if @phone_number.present?
      flash[:notice] = "Your new number is #{@phone_number.inboundno}"
    end
    @submissions = resource.submissions.lead.between(@start_date, @end_date)
  end
  
  def update
    authorize! :manipulate_campaign, @campaign
    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id)
    end
    redirect_to account_campaign_path(@account, @campaign)
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
  
  def create_new_campaign_contact_form
    @campaign = Campaign.find(params[:id])
    if @campaign.present?
      @form_text = @campaign.create_contact_form(params[:description], params[:return_url], params[:forwarding_email], params[:forwarding_bcc_email], params[:custom1_text], params[:custom2_text], params[:custom3_text], params[:custom4_text], params[:need_name], params[:need_address], params[:need_phone], params[:need_email], params[:work_category], params[:work_description], params[:date_requested], params[:time_requested], params[:other_information])
      @form = @campaign.contact_forms.last
    end
  end
  
  def orphaned
  end
  
  def new_campaign_contact_form
  end
  
end
