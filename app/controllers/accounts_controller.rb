class AccountsController < ApplicationController
  inherit_resources
  load_resource :except => [:create, :refresh_accounts]
  authorize_resource :except => [:refresh_accounts]
  before_filter :load_time_zone, :only  => [:show, :report, :report_client]
  before_filter :check_authorization, :load_resource_user
  
  def index
    @accounts           = current_user.acquainted_accounts
    @accounts.count == 1 ? (redirect_to account_path(@accounts.first.id)) : nil
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
    render :layout => false
  end
  
  def edit
    render :layout => false
  end
  
  def create
    if params[:account][:name].blank? || params[:account][:main_contact].blank? || params[:account][:industry].blank? || params[:account][:group_account].blank? 
      flash[:error] = "You forgot to fill in some fields, try creating your account again!"
    else
      @account = Account.new
      @account.name           = params[:account][:name]
      @account.main_contact   = params[:account][:main_contact]
      @account.industry       = params[:account][:industry]
      @account.group_account_id  = params[:account][:group_account].to_i
      if @account.save
        flash[:notice] = "Your account was created!"
      else
        flash[:error] = "There was an error creating your account, try again please!"
      end
    end
    redirect_to accounts_url
  end
  
  def destroy
    destroy! do |failure, success|
      success.html(:notice => "Yay! Account was successfully deleted!") {redirect_to accounts_path}
      failure.html(:notice => "Ooops, try again, your account was not deleted!") {redirect_to account_path(@account)}
    end 
  end
  
  def edit
    no_layout
  end
  
  def update 
    gu = GroupUser.find(params[:account_manager].to_i)
    @account.account_manager = gu
    @account.update_attributes(params[:account]) && @account.save ? (flash[:notice] = "Your account was updated!") : (flash[:error] = "Try again, there was an error updating account!")
    redirect_to account_path(@account)
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
                                 
    @managed_campaigns    = @account.campaigns.active.managed.to_a.sort { |a,b| a.name <=> b.name }
    @unmanaged_campaigns  = @account.campaigns.active.unmanaged.to_a.sort { |a,b| a.name <=> b.name }        
                                 
    datepicker account_path(@account)
  
    @basic_channels = @account.channels.select(&:is_basic?)
    @sem_channels   = @account.channels.select(&:is_sem?)
    @seo_channels   = @account.channels.select(&:is_seo?)
    
    
    @daily_total_leads_graph = HighChart.new('graph') do |f|
      f.title(:text => false)  
      f.y_axis({:title=> false, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:type => 'datetime', :tickInterval => 7 * 24 * 3600 * 1000, :dateTimeLabelFormats =>{:week => "%b %e"})
      f.legend(:enabled => false)
      
      f.chart(:defaultSeriesType => 'area', :backgroundColor => false)
      f.series(:name=> 'Leads', :fillOpacity => '.3', :pointInterval => 24 * 3600 * 1000, :pointStart => @start_date.to_time_in_current_zone.at_beginning_of_day.utc.to_i * 1000, :data => (@start_date..@end_date).inject([]) { |leads, date| leads << @managed_campaigns.sum { |campaign| campaign.number_of_total_leads_between(date, date) } })
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
  
  
  # /accounts/:id/report/client
  # /accounts/:id/report/client.pdf
  def report_client
    authorize! :report_client, @account
    @start_date = DateTime.now.beginning_of_month
    @end_date = DateTime.now.end_of_month
    
    @managed_campaigns    = @account.campaigns.active.managed.to_a.sort { |a,b| a.name <=> b.name }
    @unmanaged_campaigns  = @account.campaigns.active.unmanaged.to_a.sort { |a,b| a.name <=> b.name }
    
    datepicker account_path(params[:id])
    
    @cost_per_lead_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> 'Leads'}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.collect {|campaign| campaign.number_of_total_leads_between(@start_date, @end_date)}, :animation => false )
    end
    
    @pay_per_click_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> 'Leads'}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_sem?).collect(&:name) , :labels=>{:rotation=>-45 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "column"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_sem?).collect {|campaign| campaign.number_of_total_leads_between(@start_date, @end_date)}, :animation => false )
    end
    
    @organic_campaign_summary_graph = HighChart.new('graph') do |f|
      f.title({:text=> false})    
      f.y_axis({:title=> {:text=> ''}, :labels=>{:rotation=>0, :align=>'right'} })
      f.x_axis(:categories => @managed_campaigns.select(&:is_seo?).collect(&:name) , :labels=>{:rotation=>0 , :align => 'right'})
      f.legend(:enabled => false)
      
      f.options[:chart][:defaultSeriesType] = "bar"
      f.series(:name=> 'Total Leads', :data => @managed_campaigns.select(&:is_seo?).collect {|campaign| campaign.number_of_total_leads_between(@start_date, @end_date)}, :animation => false )
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
    GroupAccount.pull_salesforce_accounts
    Campaign.pull_salesforce_campaigns
    GroupAccount.cache_results_for_group_accounts
    flash[:notice] = "Accounts reloaded!"
    redirect_to :action => "index"
  end

end









