class Admin::ActivitiesController < ApplicationController
  before_filter :require_admin
  layout 'admin'
  
  def index
    @user = current_user
    #@activities = Account.leads_in_previous_hours(Time.at(params[:after].to_i + 1))
    @activities = Activity.paginate(:page => (params[:page] || 1), :order => 'timestamp DESC')
  end
  
  def update
    @user = current_user
    
    @activity = Activity.find(params[:id]) 
    params[:activity] = {}
    
    if params[:call]
      params[:activity][:review_status] = params[:call][:review_status]
    elsif params[:submission]
      params[:activity][:review_status] = params[:submission][:review_status]
    end
    
    if @activity.update_attributes(params[:activity])
      redirect_to admin_activities_path
    else
      flash[:notice] = "Something went wrong."
      redirect_to admin_activities_path
    end
    
  end

end
