class Notifier < ActionMailer::Base
  default_url_options[:host] = APP_CONFIG[:host] 

  def form_submission(submission)
    recipients    submission.contact_form.forwarding_email.split(/, \s*/)
    subject       "New CityVoice Lead!"  
    from          "CityVoice <no-reply@cityvoice.com>"
    body          :submission => submission
    sent_on       Time.now
  end

end
