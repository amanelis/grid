class ContactFormsController < ApplicationController
  
  def get_html
    @form = ContactForm.find(params[:id])
  end
  
  def create
   
    @campaign = Campaign.find(params[:campaign_id])
    if @campaign.present?
      @form = @campaign.contact_forms.build
      @form.description = params[:description]
      @form.return_url = params[:return_url]
      @form.forwarding_email = params[:forwarding_email]
      @form.forwarding_bcc_email = params[:forwarding_bcc_email]
      @form.custom1_text = params[:custom1_text]
      @form.custom2_text = params[:custom2_text]
      @form.custom3_text = params[:custom3_text]
      @form.custom4_text = params[:custom4_text]
      @form.need_name = params[:need_name]
      @form.need_address = params[:need_address]
      @form.need_phone = params[:need_phone]
      @form.need_email = params[:need_email]
      @form.work_category = params[:work_category]
      @form.work_description = params[:work_description]
      @form.date_requested = params[:date_requested]
      @form.time_requested = params[:time_requested]
      @form.other_information = params[:other_information]
      @form.save
      #@form_text = @campaign.create_contact_form(params[:description], params[:return_url], params[:forwarding_email], params[:forwarding_bcc_email], params[:custom1_text], params[:custom2_text], params[:custom3_text], params[:custom4_text], params[:need_name], params[:need_address], params[:need_phone], params[:need_email], params[:work_category], params[:work_description], params[:date_requested], params[:time_requested], params[:other_information])
      render :text => @form.get_form_text
    end
  end
  
  def new
     @campaign = Campaign.find(params[:campaign_id])
     if @campaign.present?
       @form = @campaign.contact_forms.build
     end
  end
  
end