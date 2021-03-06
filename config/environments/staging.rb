# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Enable threaded mode
# config.threadsafe!
# Use postfix for mail delivery 
#ActionMailer::Base.delivery_method = :sendmail

ActionMailer::Base.smtp_settings = {
  :address => 'smtp.sendgrid.net',
  :port => 25,
  :domain => 'cityvoice.com',
  :authentication => :plain,
  :user_name => 'ben@cityvoice.com',
  :password => 'Gr1dm41l!'
}

config.after_initialize do
  ExceptionNotification::Notifier.email_prefix = "[STAGING] "
end
