class Notifier < ActionMailer::Base
  include SendGrid
  default_url_options[:host] = APP_CONFIG[:host] 

  def form_submission(submission)
    the_recipients = submission.contact_form.forwarding_email.split(/, \s*/)
    #the_recipients << "dev@cityvoice.com"
    #the_recipients << "forms@cityvoice.com"
    sender = submission.name + ' <' + submission.from_email + '>'

    recipients    the_recipients
    subject       "New CityVoice Lead!"  
    from          "CityVoice <no-reply@cityvoice.com>"
    reply_to      sender
    body          :submission => submission
    sent_on       Time.now
    bcc           ["dev@cityvoice.com", "forms@cityvoice.com"]
  end

end
