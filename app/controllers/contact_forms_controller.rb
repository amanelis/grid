class ContactFormsController < ApplicationController
  inherit_resources
  load_resource 
  load_resource :accounts 
  load_resource :channels
  load_resource :campaigns
  
  belongs_to :account
  belongs_to :channel
  belongs_to :campaign
  
  def index
  end
  
  def new
    authorize! :manipulate_campaign, @campaign
    no_layout
  end
  
  def create
    form = @campaign.create_contact_form('', params[:contact_form][:forwarding_email])
    flash[:notice] = "Good job, you just created a contact form!"
    redirect_to channel_campaign_path(@account, @channel, @campaign) 
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