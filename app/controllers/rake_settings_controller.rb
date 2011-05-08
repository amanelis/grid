class RakeSettingsController < ApplicationController
  inherit_resources
  load_resource :except => [:create]
  load_resource :accounts
  load_resource :channels
  before_filter :load_resource_user

  belongs_to :account
  belongs_to :channel
  
  def new
    no_layout
  end
  
  def create
    @rake_setting = RakeSetting.new
    @rake_setting.channel         = @channel
    @rake_setting.percentage      = params[:rake_setting][:percentage]
    @rake_setting.start_date      = params[:rake_setting][:start_date]
    
    if @rake_setting.save
      flash[:notice] = "You have added a new rake!"
    else
      flash[:error] = "Error saving rake"
    end
    
    redirect_to channel_path(@account, @channel)
  end
  
  def edit
    no_layout
  end
  
  def update
    @rake_setting.update_attributes(params[:rake_setting])
    flash[:notice] = "Successfully update the rake!"
    redirect_to channel_path(@account, @channel)
  end
end
