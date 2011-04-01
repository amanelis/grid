class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:create]
  before_filter :require_user, :only => :destroy
  
  def new
    current_user_session ? (redirect_to dashboard_url) : (@user_session = UserSession.new)
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_to dashboard_url
    else
      flash[:error] = "Username/password was invalid."
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_to login_url
  end
end
