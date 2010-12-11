class Admin::NotifierTestController < ApplicationController
  
  def index
    render :layout => 'email'
  end
  
end