class Admin::JobStatusesController < ApplicationController
  before_filter :require_admin
  layout 'admin'
  
  def index
    @user = current_user
    @job_statuses = JobStatus.paginate(:page => (params[:page] || 1), :order => 'created_at DESC')
  end
  
  def show
    @user = current_user
    @job_status = JobStatus.find(params[:id])
  end

end
