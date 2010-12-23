class Admin::WebsitesController < ApplicationController
  before_filter :require_admin
  
  def index
    @website = Website.all
  end

  def show
    
    if params[:daterangepicker].blank?
      @website = Website.find(params[:id])
      Time.zone = @website.campaigns.first.account.time_zone
      @start_date = Date.yesterday - 1.week
      @end_date = Date.yesterday
      @visits = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
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
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue Exception
        @start_date = Date.yesterday - 1.week
        @end_date = Date.yesterday
      end
      @visits = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
      @bounces = @website.website_visits.between(@start_date, @end_date).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
      respond_to do |format|
        format.html # show.html.erb
      end
    end
  
    
  end
  
  def update
    
  end
end
