class AccountsController < ApplicationController
  load_and_authorize_resource

  # /accounts
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
    
    @accounts_data = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }
    @accounts.sort! {|a,b| a.name.downcase <=> b.name.downcase}
    
    respond_to do |format|
      format.html 
      format.js
      format.xml { render :xml => @accounts }
    end
    
  end

  # /accounts/:id
  def show
    authorize! :read, @account
    
    Time.zone = @account.time_zone  
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
                                 :spend_between]             
                                 
    if params[:daterange].blank?
      @start_date = Date.today.beginning_of_month
      @end_date = Date.yesterday
      
      @managed_campaigns    = @account.campaigns.cityvoice.sort! { |a,b| a.name <=> b.name }
      @unmanaged_campaigns  = @account.campaigns.unmanaged.sort! { |a,b| a.name <=> b.name }
      
      respond_to do |format|
        format.html 
      end
    else
      dates = params[:daterange].split(' to ') || params[:daterange].split(' - ')
      @date_range = params[:daterange]
      
      @managed_campaigns    = @account.campaigns.cityvoice.sort! { |a,b| a.name <=> b.name }
      @unmanaged_campaigns  = @account.campaigns.unmanaged.sort! { |a,b| a.name <=> b.name }
      
      begin 
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue
        @start_date = Date.today.beginning_of_month
        @end_date = Date.yesterday
        flash[:error] = "Your date entered was incorrect, we set it back to <strong>#{@start_date} to #{@end_date}</strong> for you."
        redirect_to account_path(params[:id])
      end 
    end
  end

  # /accounts/new
  def new
    authorize! :create, @account
    @account = Account.new

    respond_to do |format|
      format.html
    end
  end

  # /accounts/:id/edit
  def edit
    authorize! :edit, @account
    @account = Account.find(params[:id])
  end

  def create
    authorize! :create, @account
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

  # /accounts/:id/update
  def update
    authorize! :update, @account
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

  def destroy
    authorize! :destroy, @account
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to(accounts_url) }
    end
  end

  # /accounts/:id/report
  def report
    authorize! :read, @account
    Time.zone = @account.time_zone

    respond_to do |format|
      format.html
    end
  end
  
  # /accounts/:id/report/client /.pdf
  def report_client
    authorize! :read, @account
    Time.zone = @account.time_zone
    @month_start = (Date.today - 1.month).beginning_of_month
    @month_end = (Date.today - 1.month).end_of_month
    
    @managed_campaigns    = @account.campaigns.cityvoice.sort! { |a,b| a.name <=> b.name }
    @unmanaged_campaigns  = @account.campaigns.unmanaged.sort! { |a,b| a.name <=> b.name }
    
    
    @h = HighChart.new('graph') do |f|
      f.title({:text=>"Campaign Data Graph"}) 
      f.chart({:width=>"950"})      
      f.y_axis({:title=> {:text=> ''}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @account.campaigns.active.collect(&:name) , :labels=>{:rotation=>0 , :align => 'right'})

      f.options[:chart][:defaultSeriesType] = "bar"
      f.series(:name=> 'Total Leads',     :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end) })
      #f.series(:name=> 'Calls',           :data => @managed_campaigns.collect {|campaign| campaign.number_of_lead_calls_between(@month_start, @month_end) })
      #f.series(:name=> 'Forms',           :data => @managed_campaigns.collect {|campaign| campaign.number_of_lead_submissions_between(@month_start, @month_end) })
      #f.series(:name=> 'Total Contacts',  :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_contacts_between(@month_start, @month_end) })
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









