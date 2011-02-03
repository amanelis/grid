# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.9' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
=begin
  config.gem "bj"
  config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  config.gem "sqlite3-ruby", :lib => "sqlite3"
  config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'johnreilly-activerecord-activesalesforce-adapter', :source => 'http://gems.github.com', :lib => 'activerecord-activesalesforce-adapter'
  config.gem 'hpricot', :version => '0.8.2'
  config.gem 'httparty', :version => '0.6.1'
  config.gem 'nokogiri', :version => '1.4.3.1'
  config.gem 'authlogic', :version => '2.1.6'
  config.gem 'adwords4r', :version => '19.1.0'
  config.gem 'haml', :version => '3.0.18'
  config.gem 'i18n', :version => '0.4.0'
  config.gem 'formtastic', :version => '1.0.1'
  config.gem 'will_paginate', :version => '2.3.14', :source => 'http://gemcutter.org'
  config.gem 'sendgrid', :version => '0.1.4', :source => 'http://gemcutter.org'
  config.gem 'gchartrb', :version =>'0.8', :lib => 'google_chart', :source => 'http://gemcutter.org'
  config.gem 'static-gmaps', :version =>'0.0.3', :lib => 'static_gmaps', :source => 'http://gemcutter.org'
  config.gem 'delayed_job', :version => '2.0.3'
  config.gem 'daemons', :version => '1.0.10'
  config.gem 'exception_notification', :version => '2.3.3.0'
  config.gem 'googlecharts', :version => '1.6.0'
  config.gem 'aws-s3', :version =>'0.6.2', :lib => 'aws/s3'
  config.gem 'paperclip', :version => '2.3.3'
  config.gem 'facets', :version => '2.8.1'
  config.gem 'searchlogic', :version => '2.4.27'
  config.gem 'pdfkit', :version => '0.4.6'
  config.gem 'fastercsv', :version => '1.5.3'
  config.gem 'twiliolib', :version => '2.0.7'
  config.gem 'cancan', :version => '1.4.1'
  config.gem 'inherited_resources', :version => '1.0.6'
  config.gem 'doc_raptor', :version => '0.1.3'
=end

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'
  
  # Set the middleware for PDFKit
  # require 'pdfkit'
  config.middleware.use "PDFKit::Middleware", :print_media_type => true

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end
