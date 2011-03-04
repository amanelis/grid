class CampaignsController < ApplicationController
  inherit_resources
  load_resource
  load_resource :accounts
  load_resource :campaigns, :through => :basic_channel
  load_resource :basic_campaign, :through => :account
  load_resource :basic_channels, :through => :account, :except => [:new, :create]
  
  belongs_to :account
  belongs_to :basic_channel
  #before_filter :load_time_zone, :only  => [:show]
  
  def new
    authorize! :manipulate_account, @account
    @basic_campaign = BasicCampaign.new
    @industries = Industry.all.collect {|a| a.name}.sort!
  end
  
  def create
    authorize! :manipulate_account, @account
    bc = BasicCampaign.new
    bc.name = params[:basic_campaign][:name]
    bc.account = @account
    bc.basic_channel = @basic_channel
    bc.save
    flash[:success] = "Good job you created a campaign"
    redirect_to account_path(@account)
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
    show!
=begin  
    datepicker campaign_path(@basic_campaign)
    @phone_number = PhoneNumber.find(params[:phone_number]) unless params[:phone_number].blank?
    @submissions = resource.submissions.non_spam.between(@start_date, @end_date)
=end
  end
  
  def edit
    authorize! :manipulate_campaign, @campaign
    edit!
  end
  
  def update
    authorize! :manipulate_campaign, @campaign
    @campaign.update_attribute(:name, params[:basic_campaign][:name])
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
