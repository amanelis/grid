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
      @numbers = @campaign.get_twilio_numbers(params[:phone_number][:area_code], params[:phone_number][:forward_to])
    end
  end
  
  def create
    if params[:phone_number][:area_code].present? && params[:phone_number][:forward_to].present? && params[:phone_number][:twilio].present?
      response = @campaign.set_twilio_number(params[:phone_number][:area_code], params[:phone_number][:forward_to], @campaign.name, params[:phone_number][:twilio].gsub("+", ""))
    end
    flash[:notice] = "Good job, you just created a phone number!"
    redirect_to channel_campaign_path(@account, @channel, @campaign)
  end
  
  def available_numbers
    @numbers = @campaign.get_twilio_numbers(params[:phone_number][:area_code], params[:phone_number][:forward_to], @campaign.name)
  end
  
end