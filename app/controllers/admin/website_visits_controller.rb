class Admin::WebsiteVisitsController < ApplicationController
  before_filter :require_admin
  
  def index
    @website_visit = WebsiteVisit.all
  end

  def show
    @website_visit = WebsiteVisit.find(params[:id])
  end
  
  def update
    
  end
end
