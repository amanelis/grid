class SubmissionsController < ApplicationController
  def create    
    @submission = Submission.new(params[:submission])
    @submission.ip_address = request.remote_ip
    @submission.user_agent = request.user_agent
    if @submission.save
      # HTTP 200 OK
      head :ok
    else
       # Let's not give the (likely) bot too much info on why this failed.
      head 400
    end
  end

end
