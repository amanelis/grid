class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  
  def index
    @current_user = current_user
    @current_user.admin? ? @users = User.all : @users = User.find_by_id(current_user.id)
  end
  
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default dashboard_url
    else
      render :action => :new
    end
  end
  
  def show
    @user = @current_user
  end
  
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to person_url
    else
      render :action => :show
    end
  end
end


