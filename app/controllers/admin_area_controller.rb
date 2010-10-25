class AdminAreaController < ApplicationController
  before_filter :require_admin

  def index
    @user = current_user
    #@page = DailyTrend.find(:all, :limit => APP_CONFIG['articles_per_page'] , :order => 'trend DESC', :conditions => ["page_id NOT IN (?) and page_id NOT IN (select page_id from featured_pages)", APP_CONFIG['blacklist']] ).rand.page
    @timeline = Rails.cache.fetch("admin_data") { Account.combined_timeline_data }
    @sorted_dates = @timeline.keys.sort
    @title = "CityVoice"
    
    @accounts_data = Rails.cache.fetch("accounts_data") { Account.get_accounts_data }
    
    @sorted_by_ctr = @accounts_data.reject { |k, v| v[:account_type] !~ /SEM|Mobile/i }
    @sorted_by_ctr = @sorted_by_ctr.to_a.sort {|x, y| x[1][:ctr] <=> y[1][:ctr]}
    @sorted_by_ctr = @sorted_by_ctr[0..4]
    
    @sorted_by_leads = @accounts_data.to_a.sort {|x, y| x[1][:leads] <=> y[1][:leads]}
    @sorted_by_leads = @sorted_by_leads[0..4]
    
    @sorted_by_cpconv = @accounts_data.to_a.sort {|x, y| y[1][:cpconv] <=> x[1][:cpconv]}
    @sorted_by_cpconv = @sorted_by_cpconv[0..4]
  end

end
