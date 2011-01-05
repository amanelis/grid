class Admin::WebsitesController < ApplicationController
  before_filter :require_admin
  helper_method :sort_column, :sort_direction
  
  def index
    @website = Website.all
  end

  def show
    
    if params[:daterangepicker].blank?
      @date_range = ''
      @website = Website.find(params[:id])
      Time.zone = @website.campaigns.first.account.time_zone
      @start_date = Date.yesterday - 1.week
      @end_date = Date.yesterday
      @visits = WebsiteVisit.paginate(:all, :conditions => ['website_id = ? AND time_of_visit BETWEEN ? AND ?', @website.id, @start_date, @end_date], :page => params[:page], :order => (sort_column + " " + sort_direction), :per_page => 20)
      
      @bounces = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
      respond_to do |format|
        format.html # show.html.erb
      end
    else
      @website = Website.find(params[:id])
      Time.zone = @website.campaigns.first.account.time_zone
      # Parse the date the GET request has received
      dates = params[:daterangepicker].split(' - ')

      begin
        @date_range = params[:daterangepicker]
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue Exception
        @date_range = params[:daterangepicker]
        @start_date = Date.yesterday - 1.week
        @end_date = Date.yesterday
      end
      @visits = WebsiteVisit.paginate(:all, :conditions => ['website_id = ? AND time_of_visit BETWEEN ? AND ?', @website.id, @start_date, @end_date], :page => params[:page], :order => (sort_column + " " + sort_direction), :per_page => 20)
      #@visits = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
      @bounces = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
      respond_to do |format|
        format.html # show.html.erb
      end
    end
  
    
  end
  
  def update
    
  end
  
  
  private
  
  def sort_column
    WebsiteVisit.column_names.include?(params[:sort]) ? params[:sort] : "visitor_id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
  
end
