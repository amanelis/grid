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
    content_type  "multipart/alternative"
    body          :submission => submission
    sent_on       Time.now
  end

  def weekly_report(account, email_list = nil, date = nil, previous = nil, bcc_list = nil)
    email_list ||= account.reporting_emails.split(/, \s*/)
    date ||= Date.today.beginning_of_week
    previous ||= 6
    bcc_list ||= ["dev@cityvoice.com", "reporting@cityvoice.com"]
    from_email = account.valid_account_manager_information? ? "#{account.account_manager.name} <#{account.account_manager.email}>" : "CityVoice <support@cityvoice.com>"

    recipients    email_list
    bcc           bcc_list
    subject       "Weekly Report"  
    from          from_email
    sent_on       Time.now
    content_type  "multipart/alternative"
    body          :account_report_data => account.weekly_reporting_data(date, previous)
  end
  
end
