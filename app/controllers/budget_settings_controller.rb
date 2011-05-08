class BudgetSettingsController < ApplicationController
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
    @budget_setting = BudgetSetting.new
    @budget_setting.channel     = @channel
    @budget_setting.amount      = params[:budget_setting][:amount]
    @budget_setting.start_date  = params[:budget_setting][:start_date]
    
    if @budget_setting.save
      flash[:notice] = "You have added a new budget!"
    else
      flash[:error] = "Error saving budget"
    end
    
    redirect_to channel_path(@account, @channel)
  end
  
  def edit
    no_layout
  end
  
  def update
    @budget_setting.update_attributes(params[:budget_setting])
    flash[:notice] = "Successfully update the budget!"
    redirect_to channel_path(@account, @channel)
  end
end
