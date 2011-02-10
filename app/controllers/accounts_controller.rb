class AccountsController < ApplicationController
  inherit_resources
  load_and_authorize_resource :except   => [:export, :refresh_accounts]
  before_filter :load_time_zone, :only  => [:show, :report, :report_client]

  def index
    @accounts           = current_user.acquainted_accounts
    @accounts_statuses  = Account.account_statuses_for(@accounts)
    @accounts_types     = Account.account_types_for(@accounts)
    @passed_status      = params[:account_status] ||= 'Active' 
    @passed_type        = params[:account_type] ||= ''
    @accounts           = @accounts.select {|account| account.status == params[:account_status]} if params[:account_status].present?
    @accounts           = @accounts.select {|account| account.account_type?(params[:account_type])} if params[:account_type].present?
    @accounts_data      = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }
    @accounts.sort! {|a,b| a.name.downcase <=> b.name.downcase}
  end
  
  def new
    new!
  end
  
  def edit
    edit!
  end
  
  def create
    create! do |failure, success|
      success.html(:notice => "Yay! Account was successfully created!") {redirect_to account_path(@account)}
      failure.html(:notice => "Ooops, try again, your account was not saved!") {render 'new'}
    end
  end
  
  def destroy
    destroy! do |failure, success|
      success.html(:notice => "Yay! Account was successfully deleted!") {redirect_to accounts_path}
      failure.html(:notice => "Ooops, try again, your account was not deleted!") {redirect_to account_path(@account)}
    end 
  end
  
  def update 
    update! do |failure, success|
      success.html(:notice => "Yay! Account was successfully updated!") {redirect_to account_path(@account)}
      failure.html(:notice => "Ooops, try again, your account was not saved!") {redirect_to account_path(@account)}
    end
  end

  def show
    @total_reporting_messages = [:number_of_lead_calls_between,
                                 :number_of_all_calls_between,
                                 :number_of_lead_submissions_between,
                                 :number_of_all_submissions_between, 
                                 :number_of_total_leads_between,     
                                 :number_of_total_contacts_between,  
                                 :cost_between,                      
                                 :spend_between]  
                                 
    @managed_campaigns    = @account.campaigns.active.cityvoice.to_a.sort { |a,b| a.name <=> b.name }
    @unmanaged_campaigns  = @account.campaigns.active.unmanaged.to_a.sort { |a,b| a.name <=> b.name }        
                                 
    datepicker account_path(params[:id])
    
    @daily_total_leads_graph = HighChart.new('graph') do |f|
      f.title({:text=>"Total Daily Leads"})  
      f.y_axis({:title=> {:text=> 'Daily Leads'}, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => ((@start_date)..(@end_date)).to_a , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "line"
      f.series(:name=> 'Leads', :data => (@start_date..@end_date).inject([]) { |leads, date| leads << @managed_campaigns.sum { |campaign| campaign.number_of_total_leads_between(date, date) } })
    end
    
    @campaign_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=>"Campaign Summary"})  
      f.y_axis({:title=> {:text=> 'Leads'}, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)

      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Leads', :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_leads_between(@start_date, @end_date) })
    end
  end
  
  
  # /accounts/:id/report/client.pdf
  def report_client
    @month_start = (Date.today - 1.month).beginning_of_month
    @month_end = (Date.today - 1.month).end_of_month
    
    @managed_campaigns    = @account.campaigns.active.cityvoice.to_a.sort { |a,b| a.name <=> b.name }
    @unmanaged_campaigns  = @account.campaigns.active.unmanaged.to_a.sort { |a,b| a.name <=> b.name }
    
    @cost_per_lead_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> 'Leads'}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end)}, :animation => false )
    end
    
    @pay_per_click_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> 'Leads'}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_sem?).collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_sem?).collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end)}, :animation => false )
    end
    
    @organic_campaign_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> ''}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_seo?).collect(&:name) , :labels=>{:rotation=>0 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "bar"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_seo?).collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end)}, :animation => false )
    end
    
    respond_to do |format|
      format.html {render :layout => 'report'}
    end
  end
  
  def send_weekly_email
    @account.send_weekly_report_now
    flash[:notice] = "You have successfully sent an email!"
    redirect_to account_path(params[:id])
  end
  
  def refresh_accounts
    authorize! :refresh_accounts, Account
    GroupAccount.pull_salesforce_accounts
    Campaign.pull_salesforce_campaigns
    Account.cache_results_for_accounts
    flash[:notice] = "Accounts reloaded!"
    redirect_to :action => "index"
  end

  def export
    authorize! :export, Account
    @accounts = Account.find(:all, :order => "name")
    @outfile  = "accounts_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    
    csv_data = FasterCSV.generate do |csv|
      csv << ["Name", "Account Type", "Salesforce ID"]
      @accounts.each do |account|
        csv << [account.name, account.account_type, account.salesforce_id]
      end 
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{@outfile}"
  end 
  
  def add_customer_lobby
  end

end









