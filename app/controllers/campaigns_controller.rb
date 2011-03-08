class CampaignsController < ApplicationController
  inherit_resources
  load_resource :except => [:create]
  load_resource :accounts 
  load_resource :channels
  
  belongs_to :account
  belongs_to :channel
  
  def new
    authorize! :manipulate_account, @account
  end
  
  def create
    authorize! :manipulate_account, @account
    if @channel.channel_type == "basic"
      bc = BasicCampaign.new
      bc.account = @account
      bc.channel = @channel
      bc.name    = params[:campaign][:name]
      bc.save
      bc.campaign.save
      
      # Uncomment to provision phone numbers **************************
      number = bc.campaign.create_twilio_number(params[:campaign][:area_code], params[:campaign][:name], params[:campaign][:forward_to])
      form = bc.campaign.create_contact_form('', params[:campaign][:forwarding_email])
      flash[:notice] = "Good job, you just created a campaign!"
      redirect_to channel_campaign_path(@account, @channel, @account.campaigns.last, :form => form)
    elsif @channel.channel_type == "sem"

    elsif @channel.channel_type == "seo"
      
    end
=begin
    # flash[:error] = "You must select a campaign type" if params[:flavor] == 'Select...'
    # flash[:error] = "You must select an Industry" if params[:industry] == 'Select...'
    # flash[:error] = "Sorry, but there are no available numbers for the #{params[:area_code]} area code" if PhoneNumber.available_numbers(params[:area_code]).blank?
    # redirect_to request.referer if flash[:error].present?
    if @account.present?
      if @account.campaigns.find_by_name(params[:name]).present?
        flash[:error] = "Sorry, but a campaign with the name #{params[:name]} already exists on this account"
        redirect_to request.referer
      else
        campaign = @account.create_basic_campaign(params[:basic_channel], params[:name], :industry = params[:industry], :params[:forwarding_number], :area_code = params[:area_code])
        campaign.save
        redirect_to account_campaign_path(@account.id, campaign.id, :phone_number => PhoneNumber.first)
      end
    end
=end 
  end

  def show
    authorize! :manipulate_campaign, @campaign
  end
  
  def edit
    render :layout => false
    authorize! :manipulate_campaign, @campaign
  end
  
  def update
    authorize! :manipulate_campaign, @campaign
    @campaign.update_attributes(params[:campaign])
    flash[:notice] = "Alright, that CAMPAIGN was updated."
    redirect_to account_path(@account)
=begin
    update! do |success, failure|
      success.html {
        flash[:notice] = "Alright, that CAMPAIGN was updated."
        redirect_to account_path(@account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error updating that CAMPAIGN, you might want to try again."
        redirect_to account_path(@account) 
      }
    end
    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id)
    end
    flash[:notice] = "Account Successfully updated!"
    redirect_to account_campaign_path(@account, @campaign)
=end
  end
  
  def destroy
    authorize! :manipulate_campaign, @campaign
    destroy! do |success, failure|
      success.html {
        flash[:notice] = "Alright, that CAMPAIGN was deleted."
        redirect_to account_path(@account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error deleting that CAMPAIGN, you might want to try again."
        redirect_to account_path(@account) 
      }
    end
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
  
  def orphaned
  end
  
  def new_campaign_contact_form
  end
  
end
