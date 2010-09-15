class SubmissionsController < ApplicationController
  def create    
    @submission = Submission.new(params[:submission])
    @submission.ip_address = request.remote_ip
    @submission.user_agent = request.user_agent
    @submission.time_of_submission = DateTime.now
    if @submission.save
      # HTTP 200 OK
      Notifier.deliver_form_submission(@submission)
      redirect_to params[:submission][:retURL]
    else
      # Let's not give the (likely) bot too much info on why this failed.
      head 400
    end
  end

end
