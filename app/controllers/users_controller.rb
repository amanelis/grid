class UsersController < ApplicationController
  #before_filter :require_user, :only => [:index, :show, :edit, :update, :new]
  inherit_resources
  load_and_authorize_resource :except => [:edit, :update]
  
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
      redirect_back_or_default users_path
    else
      render :action => :new
    end
  end
  
  def edit
    @current_user = current_user
    @user = User.find(params[:id])
    @user == @current_user ? nil : (authorize! :edit, User)
  end
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:notice] = "Successfully deleted user!"
    redirect_to users_path
  end
  
  def update 
    @current_user = current_user
    @user = User.find_by_id(params[:user][:id])
    @user == @current_user ? nil : (authorize! :update, User)
    
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to edit_user_path(@user)
    else
      flash[:error] = "Error on updating account!"
      redirect_to edit_user_path(@user)
    end
  end
end

