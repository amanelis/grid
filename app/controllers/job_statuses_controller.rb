class JobStatusesController < ApplicationController
  inherit_resources
  load_and_authorize_resource
  before_filter :load_resource_user, :only => [:index, :show]
  
  def index
    @job_statuses = JobStatus.paginate(:page => (params[:page] || 1), :order => 'created_at DESC')
  end
  
  def show
    @job_status = JobStatus.find(params[:id])
  end

end
