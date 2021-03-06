class UserMailer < ActionMailer::Base
  include SendGrid
  default_url_options[:host] = APP_CONFIG[:host]
  
  def password_reset_instructions(user)  
    subject       "Password Reset Instructions"  
    from          "CityVoice Notifier"  
    recipients    user.email  
    sent_on       Time.now  
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)  
  end

end
