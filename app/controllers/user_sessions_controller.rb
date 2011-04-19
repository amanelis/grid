class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:create]
  before_filter :require_user, :only => [:destroy]
  
  def new
    current_user_session ? (redirect_to dashboard_url) : (@user_session = UserSession.new)
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "<span class=\"success-box\">Congrats, you're logged in now.</span>"
      redirect_to dashboard_url
    else
      flash[:error] = "<span class=\"error-box\">Username or password isn't working.</span"
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:notice] = "<span class=\"success-box\">You are now officially logged out.</span>"
    redirect_to login_url
  end
end
