class ActivitiesController < ApplicationController
  #before_filter :require_admin
  # Carefull, this load_and_authorize_resource function will setup all instance variables
  # for any of the default restfull rails routes.
  load_and_authorize_resource
  
  def index  
    @user = current_user
    @accounts = current_user.acquainted_accounts
    @accounts.each do |account|
      account.phone_numbers.calls
      account.contact_forms.submissions
    end
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
      flash[:notice] = "Activity updated!"
      respond_to do |format|
        format.html {redirect_to activities_path}
        format.js
      end
    else
      flash[:error] = "Something went wrong."
      respond_to do |format|
        format.html {redirect_to activities_path}
        format.js
      end
    end
    
  end

end
