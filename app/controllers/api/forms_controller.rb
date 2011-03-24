class Api::FormsController < ApplicationController
  
  def get_html
    render :text => ContactForm.find(params[:form_id]).get_form_text
  end
  
  def thank_you
    render :text => "Thank you for your submission."
  end
  
  def get_iframe
    render :text => ContactForm.find(params[:form_id]).get_iframe_code
  end
  
  def submission
    if request.post?
      unless ContactForm.exists?(params[:submission][:contact_form_id])
        # Let's not give the (likely) bot too much info on why this failed.
        head 400
        return
      end
    
      logger.debug "\n\n**********************************"
      logger.debug params[:submission].to_yaml
      logger.debug "**********************************\n\n"
    
      @submission = Submission.new(params[:submission])
      @submission.ip_address = request.remote_ip
      @submission.user_agent = request.user_agent
      @submission.time_of_submission = DateTime.now
      if @submission.empty?
        redirect_to params[:submission][:retURL]
      elsif @submission.save
        # HTTP 200 OK
        if @submission.from_email == "alex.baldwin@cityvoice.com"
          Notifier.deliver_form_submission(@submission)
          head 200
          return
        else        
          Notifier.send_later(:deliver_form_submission, @submission) unless @submission.review_status_spam? || @submission.contact_form.inactive?
        end
        @submission.update_if_duplicate
        GroupAccount.send_later(:cache_results_for_group_accounts)
        redirect_to params[:submission][:retURL]
      else
        # Let's not give the (likely) bot too much info on why this failed.
        head 400
      end 
    end
  end
  
end
