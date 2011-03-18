class UsersController < ApplicationController
  #before_filter :require_user, :only => [:index, :show, :edit, :update, :new]
  #load_and_authorize_resource :except => [:edit, :update]
  load_resource
  load_resource :account
  
  
  #
  # We want to only list out the users that the current user can manipulate
  def index
    @current_user = current_user
    @current_user.admin? ? (@users = User.all) : (@current_user.manipulable_users.compact)
  end
  
  def new
    authorize! :manipulate_account, @account
    request.request_uri != "/register" ? no_layout : nil
    @current_user = current_user
  end
  
  
  # Alright so this is the method used to adding different users to group accounts 
  # depending on who you are and what your role is.
  # The parameters for "TYPE" coming in are basically telling you what user/role
  # the user submitting the form is trying to add, here are the different roles
  # 1 -> GroupUserWrite
  # 2 -> GroupUserRead
  # 3 -> AccountUserWrite
  # 4 -> AccountUserRead
  # Based on which role is submitted that will then check the ability you have on
  # adding that user. We are validating that server side and client side.
  def create
    @current_user   = current_user
    @user           = User.new(:email => params[:user][:email], :password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
    @account        = Account.find(params[:account_id]) if params[:account_id].present?
    @group_account  = @account.group_account if params[:account_id].present?
    type            = params[:user][:type]
    
    if params[:user][:email].blank? || params[:user][:password].blank? || params[:user][:password_confirmation].blank? || params[:user][:type] == "0"
      flash[:error] = "You did not enter in correct information, please try again"
    else 
      
      if @user.save
        flash[:notice] = "User was saved!"
        
        if type == "1" || type == "2"
          @group_user                 = GroupUser.new 
          @group_user.user            = @user
          @group_user.group_account   = @group_account

          if type == "1" && @current_user.can_manipulate_account?(@account) && @current_user.group_user?
            @group_user.manipulator = true
          end
          @group_user.save
        elsif type == "3" || type == "4"
          @account_user         = AccountUser.new
          @account_user.user    = @user
          @account_user.account = @account

          if type == "3" && @current_user.can_manipulate_account?(@account) && @current_user.group_user?
            @account_user.manipulator = true
          end
          @account_user.save
        end
      else
        flash[:error] = "User was not able to be saved"
      end
    end
    
    redirect_to account_path(@account)   
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
      redirect_to users_path
    else
      flash[:error] = "Error on updating account!"
      redirect_to edit_user_path(@user)
    end
  end
end

