class AccountsController < ApplicationController
  #before_filter :require_admin
  # Carefull, this load_and_authorize_resource function will setup all instance variables
  # for any of the default restfull rails routes.
  load_and_authorize_resource
  require 'fastercsv'
  
  # GET /accounts
  # GET /accounts.xml
  def index
    authorize! :read, Account
    
    @passed_status = params[:account_status] ||= 'Active'
    @passed_type = params[:account_type] ||= ''
    
    @accounts = current_user.acquainted_accounts
    @accounts_statuses = Account.account_statuses_for(@accounts)
    @accounts_types = Account.account_types_for(@accounts)
    
    if params[:account_status].present?
      @accounts = @accounts.select {|account| account.status == params[:account_status]}
    end
      
    if params[:account_type].present?
      @accounts = @accounts.select {|account| account.account_type?(params[:account_type])}
    end
    
    #@accounts = Account.get_accounts_by_status_and_account_type(params[:account_status], params[:account_type])
    @accounts_data = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }


    ## This will pull the users accounts based on their role
    
    @accounts.sort! {|a,b| a.name.downcase <=> b.name.downcase}
    respond_to do |format|
      format.html 
    end
    
  end

  # GET /accounts/1
  # GET /accounts/1.xml
  def show      
    @account = Account.find(params[:id])
    authorize! :read, @account
    
    Time.zone = @account.time_zone
    @timeline = @account.combined_timeline_data    
    @sorted_dates = @timeline.keys.sort
    @title = @account.name
    @seo_campaign_timelines = @account.campaign_seo_combined_timeline_data
    @sem_campaign_timelines = @account.campaign_sem_combined_timeline_data
    @map_campaign_timelines = @account.campaign_map_combined_timeline_data
    @date_range = ''
    
    @total_reporting_messages = [:number_of_lead_calls_between,
                                 :number_of_all_calls_between,
                                 :number_of_lead_submissions_between,
                                 :number_of_all_submissions_between, 
                                 :number_of_total_leads_between,     
                                 :number_of_total_contacts_between,  
                                 :cost_between,                      
                                 :spend_between,                     
                                 :cost_per_lead_between,            
                                 :cost_per_contact_between]         
                                 
                                  
    
    if params[:daterange].blank?
      @start_date = Date.today.beginning_of_month
      @end_date = Date.yesterday
      
      @managed_campaigns    = @account.campaigns.cityvoice.sort! { |a,b| a.name <=> b.name }
      @unmanaged_campaigns  = @account.campaigns.unmanaged.sort! { |a,b| a.name <=> b.name }
      
      respond_to do |format|
        format.html # show.html.erb
      end
    else
      # Parse the date the GET request has received
      dates = params[:daterange].split(' to ') || params[:daterange].split(' - ')
      @date_range = params[:daterange]
      
      begin 
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue
        @start_date = Date.today.beginning_of_month
        @end_date = Date.yesterday
        flash[:error] = "Your date was incorrect, we set it back to #{@start_date} to #{@end_date}"
      end
      
      @managed_campaigns    = @account.campaigns.cityvoice.sort! { |a,b| a.name <=> b.name }
      @unmanaged_campaigns  = @account.campaigns.unmanaged.sort! { |a,b| a.name <=> b.name }

      respond_to do |format|
        format.html # show.html.erb
      end
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
  
  def report_client
    @account = Account.find(params[:id])
    Time.zone = @account.time_zone
    @month_start = (Date.today - 1.month).beginning_of_month
    @month_end = (Date.today - 1.month).end_of_month
    
    
    @h = HighChart.new('graph') do |f|
      f.title({:text=>"Campaign Data Graph"}) 
      f.chart({:width=>"950"})      
      f.y_axis({:title=> {:text=> ''}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @account.campaigns.active.collect(&:name) , :labels=>{:rotation=>0 , :align => 'right'})

      f.options[:chart][:defaultSeriesType] = "bar"
      f.series(:name=> 'Calls',          :data => @account.campaigns.active.collect {|campaign| campaign.number_of_lead_calls_between(@month_start, @month_end) })
      f.series(:name=> 'Forms',          :data => @account.campaigns.active.collect {|campaign| campaign.number_of_lead_submissions_between(@month_start, @month_end) })
      f.series(:name=> 'Total Leads',   :data => @account.campaigns.active.collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end) })
      f.series(:name=> 'Total Contacts',:data => @account.campaigns.active.collect {|campaign| campaign.number_of_total_contacts_between(@month_start, @month_end) })
    end
    
    respond_to do |format|
      format.html {render :layout => 'report'}
    end
  end

  def weekly_perf_report
    @accounts = Account.active.to_a

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def send_weekly_email
    @account = Account.find(params[:id])
    @account.send_weekly_report_now
    flash[:notice] = "You have successfully sent an email!"
    redirect_to account_path(params[:id])
  end
  
  # Simple method to reload salesforce data, accounts/campaigns
  def refresh_accounts
    authorize! :refresh_accounts, Account
    GroupAccount.pull_salesforce_accounts
    Campaign.pull_salesforce_campaigns
    Account.cache_results_for_accounts
    flash[:notice] = "Accounts reloaded!"
    redirect_to :action => "index"
  end
  
  
  # This function right now is VERY BASIC feature of exporting data to csv
  # for account managers, more options and sorting will be implemented as 
  # dev continues
  def export
    @accounts = Account.find(:all, :order => "name")
    @outfile  = "accounts_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    
    csv_data = FasterCSV.generate do |csv|
      csv << [
        "Name",
        "Account Type",
        "Salesforce ID"
      ]
      @accounts.each do |account|
        csv << [
          account.name,
          account.account_type,
          account.salesforce_id
        ]
      end # @accounts
    end # csv_array
    
    send_data csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{@outfile}"
  end 

end









