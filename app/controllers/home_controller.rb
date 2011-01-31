class HomeController < ApplicationController  
  
  def index
    @user = current_user
  end
  
  def dashboard  
    authorize! :read, Account
    @user = current_user
    if @user.admin?
      @accounts           = Account.all.count
      @active_accounts    = Account.active.count
      @inactive_accounts  = Account.inactive.count
      @reseller_accounts  = Account.reseller.count
    end
  end
  
  
end
