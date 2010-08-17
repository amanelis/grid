class UserMailer < ActionMailer::Base
  default_url_options[:host] = APP_CONFIG[:host]
  
  def forgot_password(sent_at = Time.now)
    def password_reset_instructions(user)  
      subject       "Password Reset Instructions"  
      from          "CityVoice Notifier"  
      recipients    user.email  
      sent_on       Time.now  
      body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)  
    end
  end

end
