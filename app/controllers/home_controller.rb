class HomeController < ApplicationController
  def index
    @user = current_user
  end
  
  def dashboard
    @user = current_user    
  end
end
