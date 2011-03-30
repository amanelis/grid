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
      bc.status  = "Active"

      if bc.save && bc.campaign.save
        flash[:notice] = "Good job, you just created a campaign!"
      else
        flash[:error] = "Looks like you might have already named a campaign with a similar name, please try again!"
      end
    elsif @channel.channel_type == "sem"
      name          = params[:campaign][:name]
      adwords_id    = params[:campaign][:adwords_id]
      landing_page  = params[:campaign][:landing_page]
      rake          = params[:campaign][:rake]

      sc = SemCampaign.new
      sc.account  = @account
      sc.channel  = @channel
      sc.name     = name
      sc.rake     = rake

      if sc.save && sc.campaign.save && sc.campaign.create_website(website)
        flash[:notice] = "Good job, you just created a campaign!"
      else
        flash[:error] = "Looks like you might have already named a campaign with a similar name, please try again!"
      end
    elsif @channel.channel_type == "seo"
      name      = params[:campaign][:name]
      website   = params[:campaign][:url]
      budget    = params[:campaign][:budget]
      keywords  = params[:campaign][:keywords].split("\r\n")

      sc = SeoCampaign.new
      sc.account  = @account
      sc.channel  = @channel
      sc.name     = name
      sc.budget   = budget
      sc.save
      sc.campaign.save
      # sc.campaign.create_website(website)

      w = Website.new
      w.domain = website
      w.nickname = website
      w.save
      w.create_ginza_site
      
      sc.website = w
      sc.save

      keywords.each do |keyword|
         k = Keyword.new
         k.seo_campaign = sc
         k.descriptor = keyword
         k.google_first_page = 0
         k.yahoo_first_page = 0
         k.bing_first_page = 0
         k.save 
         sc.add_ginza_keywords(keyword)
       end
       flash[:notice] = "Yay you added an SEO campaign!"
    end
    redirect_to account_path(@account)
  end

  def show
    authorize! :read, @campaign
    datepicker channel_campaign_path(@account, @channel, @campaign)

    @submissions = @campaign.submissions
    @calls       = @campaign.calls
  end

  def edit
    authorize! :manipulate_campaign, @campaign
    render :layout => false
  end

  def update
    authorize! :manipulate_campaign, @campaign
    if @campaign.is_basic?
      @campaign.update_attributes(:name => params[:campaign][:name]) ? (flash[:notice] = "Updated!") : (flash[:error] = "Ooops looks like there was an error updating your campaign, try again!")
    elsif @campaign.is_sem?
      @campaign.update_attributes(:name => params[:campaign][:name]) && @account.adwords_client.update_attributes(:reference_id => params[:campaign][:adwords_id]) && @campaign.campaign_style.update_attributes(:rake => params[:campaign][:rake])  && @campaign.website.update_attributes(:domain => params[:campaign][:landing_page]) ?  (flash[:notice] = "Updated!") : (flash[:error] = "Ooops looks like there was an error updating your campaign, try again!")
    elsif @campaign.is_seo?
      @campaign.update_attributes(:name => params[:campaign][:name]) && @campaign.website.update_attributes(:domain => params[:campaign][:url]) && @campaign.campaign_style.update_attributes(:budget => params[:campaign][:budget]) ? (flash[:notice] = "Updated!") : (flash[:error] = "Ooops looks like there was an error updating your campaign, try again!")
    end

    if params[:campaign][:adopting_phone_number].present?
      @phone_number = PhoneNumber.find(params[:campaign][:adopting_phone_number])
      @phone_number.update_attribute(:campaign_id, @campaign.id) ? (flash[:notice] = "Phone number assigned!") : (flash[:error] = "There was an error assigning number, please try again!")
    end

    redirect_to channel_campaign_path(@account, @channel, @campaign)
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
      @form_text = @campaign.create_contact_form(params[:description],
                                                 params[:return_url],
                                                 params[:forwarding_email],
                                                 params[:forwarding_bcc_email],
                                                 params[:custom1_text],
                                                 params[:custom2_text],
                                                 params[:custom3_text],
                                                 params[:custom4_text],
                                                 params[:need_name],
                                                 params[:need_address],
                                                 params[:need_phone],
                                                 params[:need_email],
                                                 params[:work_category],
                                                 params[:work_description],
                                                 params[:date_requested],
                                                 params[:time_requested],
                                                 params[:other_information])
      @form = @campaign.contact_forms.last
    end
  end

end
