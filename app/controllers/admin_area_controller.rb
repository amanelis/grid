class AdminAreaController < ApplicationController
  before_filter :require_admin
  layout 'admin'
  
  def index
    @user = current_user
    #@page = DailyTrend.find(:all, :limit => APP_CONFIG['articles_per_page'] , :order => 'trend DESC', :conditions => ["page_id NOT IN (?) and page_id NOT IN (select page_id from featured_pages)", APP_CONFIG['blacklist']] ).rand.page
    @timeline = Account.visit_count_by_date
    @sorted_dates = Account.sorted_dates
    @title = "CityVoice"
  end

end
