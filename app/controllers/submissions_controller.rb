class SubmissionsController < ApplicationController
  def index
    head 200
  end
  
  def show
    head 200
  end
  
  def create
    unless ContactForm.exists?(params[:submission][:contact_form_id])
      # Let's not give the (likely) bot too much info on why this failed.
      head 400
      return
    end
    
    @submission = Submission.new(params[:submission])
    @submission.ip_address = request.remote_ip
    @submission.user_agent = request.user_agent
    @submission.time_of_submission = DateTime.now
    @submission.set_review_status_spam if @submission.is_spam?
    if @submission.save
      # HTTP 200 OK
      Notifier.send_later(:deliver_form_submission, @submission) unless @submission.review_status_spam?
      Account.send_later(:cache_results_for_accounts)
      redirect_to params[:submission][:retURL]
    else
      # Let's not give the (likely) bot too much info on why this failed.
      head 400
    end
  end

end
