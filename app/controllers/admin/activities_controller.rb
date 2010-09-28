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
    
    @call = Call.find(params[:id]) if params[:call]
    @submission = Submission.find(params[:id]) if params[:submission]
    
    if (@call.update_attributes(params[:call]) if @call) || (@submission.update_attributes(params[:submission]) if @submission)
      redirect_to admin_activities_path
    else
      flash[:notice] = "Something went wrong."
      redirect_to admin_activities_path
    end
    
  end

end
