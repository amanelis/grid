class Admin::WebsitesController < ApplicationController
  before_filter :require_admin
  
  def index
    @website = Website.all
  end

  def show
    @website = Website.find(params[:id])
  end
  
  def update
    
  end
end
