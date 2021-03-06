class WebsitesController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
  end

  def show
    if params[:daterangepicker].blank?
      @date_range = ''
      Time.zone = @website.campaigns.first.account.time_zone
      cookies[:start_date] = Date.yesterday - 1.week
      cookies[:end_date] = Date.yesterday
      @visits = WebsiteVisit.paginate(:all, :conditions => ['website_id = ? AND time_of_visit BETWEEN ? AND ?', @website.id, cookies[:start_date], cookies[:end_date]], :page => params[:page], :order => (sort_column + " " + sort_direction), :per_page => 20)
      @bounces = @website.website_visits.between(cookies[:start_date], cookies[:end_date]).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
    else
      Time.zone = @website.campaigns.first.account.time_zone
      dates = params[:daterangepicker].split(' - ')

      begin
        @date_range = params[:daterangepicker]
        cookies[:start_date] = Date.parse(dates[0])
        cookies[:end_date] = Date.parse(dates[1])
      rescue Exception
        @date_range = params[:daterangepicker]
        cookies[:start_date] = Date.yesterday - 1.week
        cookies[:end_date] = Date.yesterday
      end
      @visits = WebsiteVisit.paginate(:all, :conditions => ['website_id = ? AND time_of_visit BETWEEN ? AND ?', @website.id, cookies[:start_date], cookies[:end_date]], :page => params[:page], :order => (sort_column + " " + sort_direction), :per_page => 20)
      @bounces = @website.website_visits.between(cookies[:start_date], cookies[:end_date]).sort { |a,b| b.time_of_visit <=> a.time_of_visit }
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
