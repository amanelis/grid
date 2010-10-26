class Admin::UsersController < ApplicationController
  before_filter :require_admin
  
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to admin_user_path(@user)
    else
      render :action => :show
    end
  end
end
