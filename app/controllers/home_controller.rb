class HomeController < ApplicationController
  before_filter :load_resource_user
  
  def index
  end
  
  def dashboard  
    if @user.admin?
      @accounts                   = current_user.acquainted_accounts
      @active_accounts            = @accounts.select(&:active?)
      @active_accounts_count      = Account.active.count
      @users_count                = User.all.count
      @leads_count                = Activity.today.count

      @total_daily_leads = HighChart.new('graph') do |f|
        f.title({:text=>"Total Daily Leads"})  
        f.y_axis({:title=> {:text=> 'Daily Leads'}, :min => 0, :labels=>{:rotation=>0, :align=>'right'} })
        f.x_axis(:categories => ((Date.yesterday - 1.month)..Date.yesterday).to_a , :labels=>{:rotation=>-45 , :align => 'right'})
        f.legend(:enabled => false)

        f.options[:chart][:defaultSeriesType] = "line"
        f.series(:name=> 'Leads', :data => ((Date.yesterday - 1.month)..Date.yesterday).inject([]) { |leads, date| leads << @active_accounts.sum { |account| account.campaigns.active.cityvoice.to_a.sum { |campaign| campaign.number_of_total_leads_between(date, date) } } })
      end
    end
  end
  
  
end
