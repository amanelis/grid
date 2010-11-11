class Admin::AccountsController < ApplicationController
  before_filter :require_admin
  
  # GET /accounts
  # GET /accounts.xml
  def index
      @passed_status = params[:account_status] ||= 'Active'
      @passed_type = params[:account_type] ||= ''
      @accounts = Account.get_accounts_by_status_and_account_type(params[:account_status], params[:account_type])
      #@accounts = Account.active.to_a if params[:accounts][:account_status] == 'Active'
      #@search_accounts= Account.name_like_all(params[:search].to_s.split).ascend_by_name
      @accounts_data = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }
      @accounts_statuses = Account.account_statuses
      @accounts_types = Account.account_types
      respond_to do |format|
        format.html # index.html.erb
      end
  end
  
  # Simple method to reload salesforce data, accounts/campaigns
  def refresh_accounts
    Account.pull_salesforce_accounts
    Campaign.pull_salesforce_campaigns
    flash[:notice] = "Accounts reloaded!"
    redirect_to :action => "index"
  end

  # GET /accounts/1
  # GET /accounts/1.xml
  def show    
    @account = Account.find(params[:id])
    Time.zone = @account.time_zone
    @timeline = @account.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
    @title = @account.name
    @seo_campaign_timelines = @account.campaign_seo_combined_timeline_data
    @sem_campaign_timelines = @account.campaign_sem_combined_timeline_data
    @map_campaign_timelines = @account.campaign_map_combined_timeline_data

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /accounts/new
  # GET /accounts/new.xml
  def new
    @account = Account.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /accounts/1/edit
  def edit
    @account = Account.find(params[:id])
  end

  # POST /accounts
  # POST /accounts.xml
  def create
    @account = Account.new(params[:account])

    respond_to do |format|
      if @account.save
        flash[:notice] = 'Account was successfully created.'
        format.html { redirect_to(@account) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /accounts/1
  # PUT /accounts/1.xml
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        flash[:notice] = 'Account was successfully updated.'
        format.html { redirect_to(@account) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.xml
  def destroy
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to(accounts_url) }
    end
  end

  def report
    @account = Account.find(params[:id])
    Time.zone = @account.time_zone

    respond_to do |format|
      format.html # show.html.erb
    end
    
  end

  def weekly_perf_report
    @accounts = Account.active.to_a

    respond_to do |format|
      format.html # show.html.erb
    end
  end

end
