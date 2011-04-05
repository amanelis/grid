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
    if request.post?
      @numbers = @campaign.get_twilio_numbers(params[:phone_number][:area_code], params[:phone_number][:forward_to], @campaign.name)
    end
  end
  
  def create
    render :text => params.inspect
=begin
    number = @campaign.create_twilio_number(params[:phone_number][:area_code], @campaign.name, params[:phone_number][:forward_to])
    flash[:notice] = "Good job, you just created a phone number!"
    redirect_to channel_campaign_path(@account, @channel, @campaign)
=end
  end
  
  def available_numbers
    @numbers = @campaign.get_twilio_numbers(params[:phone_number][:area_code], params[:phone_number][:forward_to], @campaign.name)
  end
  
end