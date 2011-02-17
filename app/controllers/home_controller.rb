class HomeController < ApplicationController
  before_filter :load_resource_user, :only => [:index, :dashboard]
  
  def index
  end
  
  def dashboard  
    if current_user
      
      if @user.admin? || @user.group_user?
        @accounts               = current_user.acquainted_accounts
        @active_accounts        = @accounts.select(&:active?)
        @active_accounts_count  = @active_accounts.count
        @users_count            = User.all.count
        
        if @user.admin?
          @leads_count            = (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[:admin].last
        else
          @leads_count            = @user.group_users.to_a.sum do |group_user|
            (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[group_user.group_account.id].last
          end
        end

        @cv_total_daily_leads = HighChart.new('graph') do |f|
          f.title({:text=> false})  
          f.y_axis({:title=> {:text=> 'Daily Leads'}, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
          f.x_axis(:categories => (Rails.cache.fetch("dashboard_dates") { GroupAccount.dashboard_dates }) , :labels=>{:rotation=>-45 , :align => 'right'})
          f.options[:chart][:defaultSeriesType] = "line"
          
          @user.admin? || @user.group_users.count == 1 ? f.legend(:enabled => false) : f.legend(:enabled => true)


          if @user.admin? 
            f.series(:name=> 'Leads', :data => (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[:admin])
          else
            @user.group_users.each do |group_user|
              f.series(:name=> 'Leads', :data => (Rails.cache.fetch("dashboard_data_hash") { GroupAccount.dashboard_data_hash })[group_user.group_account.id])
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
