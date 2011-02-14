class HomeController < ApplicationController
  before_filter :load_resource_user, :only => [:index, :dashboard]
  
  def index
  end
  
  def dashboard  
    if current_user
      if @user.admin?
        
        ############### Need data

      elsif @user.group_user?
        @accounts               = current_user.acquainted_accounts
        @active_accounts        = @accounts.select(&:active?)
        @active_accounts_count  = Account.active.count
        @users_count            = User.all.count
        @leads_count            = (Rails.cache.fetch("dashboard_data") { Account.dashboard_data }).last

        @cv_total_daily_leads = HighChart.new('graph') do |f|
          f.title({:text=> false})  
          f.y_axis({:title=> {:text=> 'Daily Leads'}, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
          f.x_axis(:categories => (Rails.cache.fetch("dashboard_dates") { Account.dashboard_dates }) , :labels=>{:rotation=>-45 , :align => 'right'})
          f.legend(:enabled => false)

          f.options[:chart][:defaultSeriesType] = "line"
          f.series(:name=> 'Leads', :data => (Rails.cache.fetch("dashboard_data") { Account.dashboard_data }))
        end
      end
    else
      
    end
  end
  
  
end
