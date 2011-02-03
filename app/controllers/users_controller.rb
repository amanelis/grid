class UsersController < ApplicationController
  before_filter :require_user, :only => [:index, :show, :edit, :update]
  
  def index
    @current_user = current_user
    @current_user.admin? ? @users = User.all : @users = User.find_by_id(@current_user.id)
  end
  
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save 
      flash[:notice] = "Account registered!"
      redirect_to dashboard_url
    else
      flash[:error] = "There was an error creating your account!"
      render :action => :new
    end
  end
  
  def show
    @current_user = current_user
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find_by_id(params[:user][:id])
    @user.update_attributes(params[:user]) ? (flash[:notice] = "Account updated!", redirect_to user_path(@user)) : (flash[:notice] = "Error on updating account!", redirect_to person_url)
  end
end


