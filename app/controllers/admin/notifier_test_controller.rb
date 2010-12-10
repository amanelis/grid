class Admin::AccountsController < ApplicationController
  
  def index
    render :layout => 'email'
  end
  
end