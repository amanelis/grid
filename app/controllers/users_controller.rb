class UsersController < ApplicationController
  before_filter :require_user, :only => [:index, :show, :edit, :update]
  
  def index
    @current_user = current_user
    @current_user.admin? ? @users = User.all : @users = User.find_by_id(@current_user.id)
  end
  
  def new
    redirect_to root_url
    @user = User.new
  end
  
  def create
    redirect_to root_url
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default dashboard_url
    else
      render :action => :new
    end
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @current_user = current_user
    @user = User.find(params[:id])
  end
  
  def update 
    @user = User.find_by_id(params[:user][:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to edit_user_path(@user)
    else
      flash[:error] = "Error on updating account!"
      redirect_to edit_user_path(@user)
    end
  end
end

