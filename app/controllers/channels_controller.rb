class ChannelsController < ApplicationController
  inherit_resources
  load_resource
  load_resource :account
  belongs_to :account
  
  def new
    authorize! :manipulate_account, @account
    render :layout => false
  end
  
  def show
    authorize! :read, @channel
  end
  
  def edit
    authorize! :manipulate_account, @account
    render :layout => false
  end
  
  def update
    update! do |success, failure|
      success.html {
        flash[:notice] = "Awesome! You just created updated your channel!"
        redirect_to account_path(@channel.account) 
      }
      failure.html {
        flash[:error] = "Ooops, there was an error updating that Channel, you might want to try again."
        redirect_to edit_channel_path(@channel.account)
      }
    end
  end
  
  def create
    @channel = Channel.new
    @channel.account = @account
    @channel.name = params[:channel][:name]
    @channel.set_type_basic
    @channel.cycle_start_day = params[:channel][:cycle_start_day]

    if @channel.save
      if params[:channel][:channel_type].include?("seo")
        @channel.set_type_seo
        @channel.save
      elsif params[:channel][:channel_type].include?("sem")
        @channel.set_type_sem
        @channel.save

        # Adding rake and budget to a SEM channel
        @budget_setting = BudgetSetting.new
        @rake_setting   = RakeSetting.new

        @budget_setting.channel     = @channel
        @rake_setting.channel       = @channel

        @budget_setting.amount     = params[:budget][:amount]
        @rake_setting.percentage    = params[:rake][:percentage]

        @budget_setting.start_date  = params[:budget][:start_date]
        @rake_setting.start_date    = params[:rake][:start_date]

        @budget_setting.save 
        @rake_setting.save
        flash[:notice] = "Good job, your channel has been created!"
      elsif params[:channel][:channel_type].include?("basic") || params[:channel][:channel_type].blank?
        @channel.set_type_basic
        @channel.save
      end
    else
      flash[:error] = "Looks like there was en error saving your channel, please try again."
    end
    
    redirect_to account_path(@account)
  end
  
  def destroy
    destroy! do |success, failure|
      success.html {
        flash[:notice] = "Alright, that channel was deleted."
        redirect_to account_path(@channel.account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error deleting that Channel"
        render 'new'
      }
    end
  end
end
