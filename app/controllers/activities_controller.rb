class ActivitiesController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :check_authorization

  def index
    @user       = current_user
    @accounts   = current_user.acquainted_accounts
    @activities = Activity.paginate(:page => (params[:page] || 1), :order => 'timestamp DESC', :per_page => 50)
  end

  def update
    @user     = current_user
    @activity = Activity.find(params[:id])
    params[:activity][:review_status] = params[:call][:review_status] if params[:call]
    params[:activity][:review_status] = params[:submission][:review_status] if params[:submission]

    # This is a tad messy but for now this will redirect based on what page you are updating the activity from, campaign#show or activities#index
    # Activity is trying to be updated from the campaigns#show page, we want to redirect user back to campaign page
    unless params[:activity][:campaign_id].blank?
      @activity.update_attributes!(:review_status => params[:activity][:review_status]) ? (flash[:notice] = "Activities updated successfully!", respond("html", campaign_path(params[:activity][:campaign_id]))): (flash[:error] = "Activities were not updated!", respond("html", campaign_path(params[:activity][:campaign_id])))
    else
      @activity.update_attributes!(params[:activity]) ? (flash[:notice] = "Activities updated successfully!", respond("html", activities_path)) : (flash[:error] = "Activities were not updated!", respond("html", activities_path))
    end
    
    if params[:activity][:description].blank?
      flash.now[:error] = "Looks like your description was invalid"
      respond_to do |format|
        format.js
      end
    else
      @activity.update_attributes(:description => params[:activity][:description])
      respond_to do |format|
        format.js
        format.html
      end
    end
    
  end

  def show
    no_layout
  end

end
