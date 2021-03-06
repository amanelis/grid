class WebsiteVisitsController < ApplicationController
  inherit_resources
  load_and_authorize_resource

  def index
  end

  def show
    if params[:daterangepicker].blank?
      cookies[:start_date] = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
      cookies[:end_date] = Date.yesterday
    else
      dates = params[:daterangepicker].split(' - ')
      begin
        cookies[:start_date] = Date.parse(dates[0])
        cookies[:end_date] = Date.parse(dates[1])
      rescue Exception
        cookies[:start_date] = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
        cookies[:end_date] = Date.yesterday
        cookies[:end_date] = Date.yesterday
      end
    end
  end

  def update
  end

  def global_visitor
    @website_visit = WebsiteVisit.find(params[:id])

    if params[:daterangepicker].blank?
      cookies[:start_date] = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
      cookies[:end_date] = Date.yesterday
    else
      dates = params[:daterangepicker].split(' - ')
      begin
        cookies[:start_date] = Date.parse(dates[0])
        cookies[:end_date] = Date.parse(dates[1])
      rescue Exception
        cookies[:start_date] = @website_visit.website.first_visit_date_by_visitor(@website_visit.visitor_id)
        cookies[:end_date] = Date.yesterday
        cookies[:end_date] = Date.yesterday
      end
    end
  end

  private
    def sort_column
      WebsiteVisit.column_names.include?(params[:sort]) ? params[:sort] : "visitor_id"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

end
