class SubmissionsController < ApplicationController
  def create    
    @submission = Submission.new(params)
    @submission.ip_address = request.remote_ip
    @submission.user_agent = request.user_agent
    logger.debug "referer : #{request.referer}"
    logger.debug "============================================================="
    logger.debug "Submission attributes hash : #{@submission.attributes.inspect}" 
    if @submission.save
      # HTTP 200 OK
      Notifier.deliver_form_submission(@submission)
      redirect_to params[:retURL]
    else
       # Let's not give the (likely) bot too much info on why this failed.
      head 400
    end
  end

end
