class AccountsController < ApplicationController
  inherit_resources
  load_and_authorize_resource :except => [:export, :refresh_accounts]
  before_filter :load_time_zone, :only => [:show, :report, :report_client]

  def index
    @accounts = current_user.acquainted_accounts
    @accounts_statuses = Account.account_statuses_for(@accounts)
    @accounts_types = Account.account_types_for(@accounts)
    
    @passed_status = params[:account_status] ||= 'Active' 
    @passed_type = params[:account_type] ||= ''
    
    @accounts = @accounts.select {|account| account.status == params[:account_status]} if params[:account_status].present?
    @accounts = @accounts.select {|account| account.account_type?(params[:account_type])} if params[:account_type].present?

    @accounts_data = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }
    @accounts.sort! {|a,b| a.name.downcase <=> b.name.downcase}
    respond("html", nil, "xml", @accounts) 
  end

  def show
    @date_range = ''
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
                                 
    if params[:daterange].blank?
      @start_date = Date.yesterday.beginning_of_month
      @end_date = Date.yesterday
    else
      dates = params[:daterange].split(' to ') || params[:daterange].split(' - ')
      @date_range = params[:daterange]
      begin 
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue
        @start_date = Date.yesterday.beginning_of_month
        @end_date = Date.yesterday
        flash[:error] = "The date you entered was incorrect, we set it back to <strong>#{(@start_date).to_s(:long)} to #{@end_date.to_s(:long)}</strong> for you."
        respond("html", account_path(params[:id]))
      end 
    end
    
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
 
  def new
  end

  def edit
  end

  def create
    create!(:notice => "Account was successfully created!") { accounts_path }
  end

  def update
    update!(:notice => "Account was updated successfully!") { accounts_path }
  end

  def destroy
    destroy!(:notice => "Account was successfully deleted!") { accounts_path }
  end

  # /accounts/:id/report
  def report
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
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end) })
    end
    
    @pay_per_click_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> 'Leads'}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_sem?).collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_sem?).collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end) })
    end
    
    @organic_campaign_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> ''}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_seo?).collect(&:name) , :labels=>{:rotation=>0 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "bar"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_seo?).collect {|campaign| campaign.number_of_total_leads_between(@month_start, @month_end) })
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

end









