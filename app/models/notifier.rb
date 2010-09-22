class Notifier < ActionMailer::Base
  include SendGrid
  default_url_options[:host] = APP_CONFIG[:host] 

  def form_submission(submission)
    the_recipients = submission.contact_form.forwarding_email.split(/, \s*/)
    the_bcc_recipients = (submission.contact_form.forwarding_bcc_email || "").split(/, \s*/)
    sender = submission.name + ' <' + submission.from_email + '>'

    recipients    the_recipients
    bcc           the_bcc_recipients
    subject       "New CityVoice Lead!"  
    from          "CityVoice <no-reply@cityvoice.com>"
    reply_to      sender
    body          :submission => submission
    sent_on       Time.now
  end

end
