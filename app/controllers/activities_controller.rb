class ActivitiesController < ApplicationController
  load_and_authorize_resource
  
  def index  
    @user = current_user
    @accounts = current_user.acquainted_accounts 
    # @activities_calls       = @accounts.collect {|account| account.phone_numbers.calls}.flatten.sort {|a,b| b.timestamp <=> a.timestamp}.paginate(:page => (params[:page] || 1), :order => 'timestamp DESC', :per_page => 150)
    # @activities_submissions = @accounts.collect {|account| account.contact_forms.submissions}.flatten.sort {|a,b| b.timestamp <=> a.timestamp}.paginate(:page => (params[:page] || 1), :order => 'timestamp DESC', :per_page => 150)
    @activities = Activity.paginate(:page => (params[:page] || 1), :order => 'timestamp ASC', :per_page => 100)
    
    respond("html", nil, "js", nil)
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
