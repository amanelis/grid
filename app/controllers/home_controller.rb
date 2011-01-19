class HomeController < ApplicationController
  def index
    @user = current_user
  end
  
  def dashboard
    @user = current_user
    #@activities = Activity.find(:all, :conditions => ["timestamp > ?", Time.at(params[:after].to_i + 1)])
  end
end
