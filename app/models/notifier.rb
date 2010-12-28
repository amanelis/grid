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

  def weekly_report(account, email_list = nil, date = nil)
    date ||= Date.today.beginning_of_week
    email_list ||= account.reporting_emails.split(/, \s*/)

    recipients    email_list
    subject       "Weekly Report"  
    from          "CityVoice <no-reply@cityvoice.com>"
    sent_on       Time.now
    content_type  "multipart/alternative"
    part :content_type => "text/html", :body => render_message("weekly_report", :account_report_data => account.previous_days_report_data(date, 6))
    part :content_type => "text/plain", :body => render_message("weekly_report", :account_report_data => account.previous_days_report_data(date, 6))
  end

end
