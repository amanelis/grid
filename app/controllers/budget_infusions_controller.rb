class BudgetInfusionsController < ApplicationController
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
    @budget_infusion = BudgetInfusion.new
    @budget_infusion.channel     = @channel
    @budget_infusion.amount      = params[:budget_infusion][:amount]
    @budget_infusion.commitment_date  = params[:budget_infusion][:commitment_date]

    if @budget_infusion.save
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
    @budget_infusion.update_attributes(params[:budget_infusion])
    flash[:notice] = "Successfully update the budget!"
    redirect_to channel_path(@account, @channel)
  end
  
end
