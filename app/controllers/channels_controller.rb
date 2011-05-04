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
    
    @current_start_date = @channel.current_start_date
    @current_end_date   = @channel.current_end_date
  end
  
  def edit
    authorize! :manipulate_account, @account
    render :layout => false
  end
  
  def update
    @channel.name = params[:channel][:name]
    @channel.cycle_start_day = params[:channel][:cycle_start_day]

    if @channel.save
      if @channel.is_seo?
      elsif @channel.is_sem?
        if @channel.is_virgin?
          @budget_setting = BudgetSetting.new
          @rake_setting   = RakeSetting.new

          @budget_setting.amount      = params[:budget][:amount]
          @rake_setting.percentage    = params[:rake][:percentage]

          @budget_setting.start_date  = params[:budget][:start_date]
          @rake_setting.start_date    = params[:rake][:start_date]

          @channel.budget_settings << @budget_setting
          @channel.rake_settings << @rake_setting
        end
        flash[:notice] = "Channel updated!"
      elsif @channel.is_basic?
      end
      
    else
      flash[:error] = "Did not update the channel"
    end
    
    redirect_to account_path(@channel.account, :cycle_start_day => params[:channel][:cycle_start_day]) 
  end
  
  def create
    @channel = Channel.new
    @channel.account = @account
    @channel.name = params[:channel][:name]
    @channel.set_type_basic
    @channel.cycle_start_day = params[:channel][:cycle_start_day]

 
    if params[:channel][:channel_type].include?("seo")
      @channel.set_type_seo
    elsif params[:channel][:channel_type].include?("sem")
      @channel.set_type_sem

      # Adding rake and budget to a SEM channel
      @budget_setting = BudgetSetting.new
      @rake_setting   = RakeSetting.new

      @budget_setting.amount      = params[:budget][:amount]
      @rake_setting.percentage    = params[:rake][:percentage]

      @budget_setting.start_date  = params[:budget][:start_date]
      @rake_setting.start_date    = params[:rake][:start_date]

      @channel.budget_settings << @budget_setting
      @channel.rake_settings << @rake_setting
      
      if @channel.save
        flash[:notice] = "Good job, your channel has been created!"
      else
        flash[:error] = "There was an error with your #{@channel.errors.each{|attr,msg| puts "#{attr} - #{msg}" }} in channel creation. Please try again!"
      end
    elsif params[:channel][:channel_type].include?("basic") || params[:channel][:channel_type].blank?
      @channel.set_type_basic
      @channel.save
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
