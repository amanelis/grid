class ActivitiesController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  
  def index  
    @user       = current_user
    @accounts   = current_user.acquainted_accounts 
    @activities = Activity.paginate(:page => (params[:page] || 1), :order => 'timestamp DESC', :per_page => 50)
    respond("html", nil, "js", nil)
  end
  
  def update
    @user     = current_user
    @activity = Activity.find(params[:id])
    params[:activity][:review_status] = params[:call][:review_status] if params[:call]
    params[:activity][:review_status] = params[:submission][:review_status] if params[:submission]
    @activity.update_attributes!(params[:activity]) ? flash[:notice] = "Activities updated successfully!" : flash[:error] = "Activities were not updated!"
    respond("html", activities_path)
  end

end
