class Admin::WebsiteVisitsController < ApplicationController
  before_filter :require_admin
  
  def index
    @website_visit = WebsiteVisit.all
  end

  def show
    if params[:daterangepicker].blank?
      @website_visit = WebsiteVisit.find(params[:id])
      @start_date = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
      @end_date = Date.yesterday

      respond_to do |format|
        format.html # show.html.erb
      end
    else
      @website_visit = WebsiteVisit.find(params[:id])
      # Parse the date the GET request has received
      dates = params[:daterangepicker].split(' - ')

      begin
        @start_date = Date.parse(dates[0])
        @end_date = Date.parse(dates[1])
      rescue Exception
        @start_date = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
        @end_date = Date.yesterday
        @end_date = Date.yesterday
      end

      respond_to do |format|
        format.html # show.html.erb
      end
    end
  end
  
  def update
    
  end
end
