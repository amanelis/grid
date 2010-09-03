class Notifier < ActionMailer::Base
  default_url_options[:host] = APP_CONFIG[:host] 

  def form_submission(submission)
    subject       "New CityVoice Lead!"  
    from          "CityVoice <no-reply@cityvoice.com>"
    #recipients    [email1, email2]
    recipients    #TODO
    body          :submission => submission
    sent_on       Time.now
  end

end
