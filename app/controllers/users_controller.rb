class UsersController < ApplicationController
  #before_filter :require_user, :only => [:index, :show, :edit, :update, :new]
  #load_and_authorize_resource :except => [:edit, :update]
  inherit_resources
  load_resource
  
  #
  # We want to only list out the users that the current user can manipulate
  def index
    @current_user = current_user
    @users = @current_user.manipulable_users
  end
  
  def new
    authorize! :create, User
    no_layout
    @user = User.new
  end
  
  def create
    @current_user = current_user
    @account = Account.find(params[:account_id]) if params[:account_id].present?

    if @current_user.group_user?
      if @current_user.can_manipulate_account?(@account)
        
      else
        
      end
      
    elsif @current_user.user?
      
    elsif @current_user.admin?
      
    end
    
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "You just added a new user!"
      redirect_back_or_default users_path
    else
      flash.now[:error] = "User was not able to be saved, please try again!"
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

