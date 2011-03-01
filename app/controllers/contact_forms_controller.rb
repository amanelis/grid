class ContactFormsController < ApplicationController
  
  def index
    @campaign = Campaign.find(params[:campaign_id])
    if @campaign.present?
      @forms = @campaign.contact_forms
    end
  end
  
  def new
     @campaign = Campaign.find(params[:campaign_id])
     if @campaign.present?
       @form = @campaign.contact_forms.build
     end
  end
  
  def create
    @campaign = Campaign.find(params[:campaign_id])
    if @campaign.present?
      @form = @campaign.create_contact_form(params[:description], 
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
      redirect_to contact_form_path(@form.id)
    end
  end
  
  def show
    @form = ContactForm.find(params[:id])
  end
  
  def get_html
    render :text => ContactForm.find(params[:id]).html_block
  end
  
  def thank_you
    render :text => "Thank you for your submission."
  end
  
  def get_iframe
    render :text => ContactForm.find(params[:id]).get_iframe_code
  end
end