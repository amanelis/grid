class UsersController < ApplicationController
  #before_filter :require_user, :only => [:index, :show, :edit, :update, :new]
  #load_and_authorize_resource :except => [:edit, :update]
  inherit_resources
  load_resource
  
  #
  # We want to only list out the users that the current user can manipulate
  def index
    @current_user = current_user
    @users = @current_user.manipulable_users.compact
  end
  
  def new
    authorize! :create, User
    no_layout
    @user = User.new
    @account = Account.find(params[:account_id]) if params[:account_id].present?
  end
  
  def create
    @current_user   = current_user
    @account        = Account.find(params[:account_id]) if params[:account_id].present?
    @user           = User.new(:email => params[:user][:email], :password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
    @group_account  = @account.group_account
    type            = params[:user][:type]
    
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "You just added a new user!"
    else
      flash.now[:error] = "User was not able to be saved, please try again!"
      render :action => :new
    end

    if type == "1" || type == "2"
      @group_user                 = GroupUser.new 
      @group_user.user            = @user
      @group_user.group_account   = @group_account
      
      if type == "1" && @current_user.can_manipulate_account?(@account)
        @group_user.manipulator = true
      end
      
      @group_user.save
      redirect_to users_path
      
    elsif type == "3" || type == "4"
      @account_user         = AccountUser.new
      @account_user.user    = @user
      @account_user.account = @account
      
      if type == "3" && @current_user.can_manipulate_account?(@account)
        @account_user.manipulator = true
      end
      
      @account_user.save
      redirect_to users_path
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

