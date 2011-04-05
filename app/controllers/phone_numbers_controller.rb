class PhoneNumbersController < ApplicationController
  inherit_resources
  load_resource :accounts,  :except => [:connect]
  load_resource :channels,  :except => [:connect]
  load_resource :campaigns, :except => [:connect]
  
  belongs_to :account
  belongs_to :channel
  belongs_to :campaign
  
  def new
    authorize! :manipulate_campaign, @campaign
    no_layout
  end
  
  def create
    number = @campaign.create_twilio_number(params[:phone_number][:area_code], @campaign.name, params[:phone_number][:forward_to])
    flash[:notice] = "Good job, you just created a phone number!"
    redirect_to channel_campaign_path(@account, @channel, @campaign)
  end
  
end