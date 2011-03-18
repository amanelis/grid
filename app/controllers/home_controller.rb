class HomeController < ApplicationController
  before_filter :load_resource_user, :only => [:index, :dashboard]
  
  def index
  end
  
  def dashboard  
    if current_user
      
      if @user.admin? || @user.group_user? || @user.account_user?
        @accounts               = current_user.acquainted_accounts
        @active_accounts        = @accounts.select(&:active?)
        @accounts_count         = @accounts.count
        @active_accounts_count  = @active_accounts.count
        @users_count            = User.all.count
        @dashboard_dates        = (Rails.cache.fetch("dashboard_dates") { GroupAccount.dashboard_dates })
        @account_users_data     = @user.account_users.collect(&:account).inject({}) { |results, account| results[account.id] = @dashboard_dates.inject([]) { |leads, date| leads << account.campaigns.active.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) } }; results }
        
        
        if @user.admin?
          @leads_count            = (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[:admin].last
        elsif @user.group_user?
          @leads_count            = @user.group_users.to_a.sum do |group_user|
            (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[group_user.group_account.id].last
          end
        else
          @leads_count  =  @user.account_users.to_a.sum do |account_user|
            @account_users_data[account_user.account.id].last
          end
        end

        @total_daily_leads = HighChart.new('graph') do |f|
          f.title({:text=> false})  
          f.y_axis({:title=> false, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
          f.x_axis(:categories => (Rails.cache.fetch("dashboard_dates") { GroupAccount.dashboard_dates }) , :labels=>{:rotation=>-45 , :align => 'right'})
          f.options[:chart][:defaultSeriesType] = "area"
          
          @user.admin? || @user.group_users.count == 1 ? f.legend(:enabled => false) : f.legend(:enabled => true)


          if @user.admin? 
            f.series(:name=> 'Leads', :fillOpacity => '.3', :data => (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[:admin])
          elsif @user.group_user?
            @user.group_users.each do |group_user|
              f.series(:name=> 'Leads', :fillOpacity => '.3', :data => (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[group_user.group_account.id])
            end
          else
            @user.account_users.each do |account_user|
              f.series(:name=> 'Leads', :fillOpacity => '.3', :data => @account_users_data[account_user.account.id])
            end
          end
        end
      else
        ## User
      end
    else
      flash[:error] = "Ooops, looks like you do not have access yet to view that page!"
      redirect_to root_url
    end
  end
  
  
end
