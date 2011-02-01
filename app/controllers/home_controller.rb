class HomeController < ApplicationController  
  
  def index
    @user = current_user
  end
  
  def dashboard  
    authorize! :read, Account
    @user = current_user
    if @user.admin?
      @active_accounts  = Account.active.count
      @users            = User.all.count
      @leads            = Activity.today.count
    end
  end
  
  
end
