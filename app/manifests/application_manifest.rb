require "#{File.dirname(__FILE__)}/../../vendor/plugins/moonshine/lib/moonshine.rb"
class ApplicationManifest < Moonshine::Manifest::Rails
  # The majority of your configuration should be in <tt>config/moonshine.yml</tt>
  # If necessary, you may provide extra configuration directly in this class
  # using the configure method. The hash passed to the configure method is deep
  # merged with what is in <tt>config/moonshine.yml</tt>. This could be used,
  # for example, to store passwords and/or private keys outside of your SCM, or
  # to query a web service for configuration data.
  #
  # In the example below, the value configuration[:custom][:random] can be used in
  # your moonshine settings or templates.
  #
  # require 'net/http'
  # require 'json'
  # random = JSON::load(Net::HTTP.get(URI.parse('http://twitter.com/statuses/public_timeline.json'))).last['id']
  # configure({
  #   :custom => { :random => random  }
  # })
  
  recipe :mysql_gem, :apache_server, :passenger_gem, :passenger_configure_gem_path, :passenger_apache_module, :passenger_site,
    :rails_rake_environment, :rails_gems, :rails_directories, :rails_logrotate,
    :ntp, :time_zone, :postfix, :cron_packages, :motd, :security_updates
  
  configure(:iptables => { :rules => [
     '-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT',
     '-A INPUT -p icmp -j ACCEPT',
     '-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT',
     '-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT',
     '-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT',
     '-A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT',
     '-A INPUT -s 127.0.0.1 -j ACCEPT'
   ]},
   :memcached => {
     :max_memory => '256',     # default is 64
     :client => '1.7.2',
     :enable_on_boot => true  # maybe you want god to start it instead of init
   } 
   )

  # The default_stack recipe install Rails, Apache, Passenger, the database from
  # database.yml, Postfix, Cron, logrotate and NTP. See lib/moonshine/manifest/rails.rb
  # for details. To customize, remove this recipe and specify the components you want.
  # recipe :default_stack
  
  plugin :iptables
  plugin :ssh
  
  recipe :iptables
  recipe :ssh
  
  recipe :memcached

  # Add your application's custom requirements here
  def application_packages
    # If you've already told Moonshine about a package required by a gem with
    # :apt_gems in <tt>moonshine.yml</tt> you do not need to include it here.
    # package 'some_native_package', :ensure => :installed

    # some_rake_task = "/usr/bin/rake -f #{configuration[:deploy_to]}/current/Rakefile custom:task RAILS_ENV=#{ENV['RAILS_ENV']}"
    # cron 'custom:task', :command => some_rake_task, :user => configuration[:user], :minute => 0, :hour => 0
    cron 'pull_salesforce_accounts', :command => "/home/deploy/grid/current/script/runner -e production Account.pull_salesforce_accounts", :user => configuration[:user], :minute => 1, :hour => 22
    cron 'get_salesforce_numbers', :command => "/home/deploy/grid/current/script/runner -e production PhoneNumber.get_salesforce_numbers", :user => configuration[:user], :minute => 31, :hour => 22
    cron 'pull_salesforce_campaigns', :command => "/home/deploy/grid/current/script/runner -e production Campaign.pull_salesforce_campaigns", :user => configuration[:user], :minute => 45, :hour => 22
    cron 'update_calls', :command => "/home/deploy/grid/current/script/runner -e production Call.update_calls", :user => configuration[:user], :minute => 5, :hour => '*/8'
    cron 'add_websites', :command => "/home/deploy/grid/current/script/runner -e production Website.add_websites", :user => configuration[:user], :minute => 1, :hour => 23
    cron 'data_pull_websites_visits', :command => "/home/deploy/grid/current/script/runner -e production WebsiteVisit.data_pull_websites_visits", :user => configuration[:user], :minute => 45, :hour => '*/8'
    cron 'update_keywords_from_salesforce', :command => "/home/deploy/grid/current/script/runner -e production Keyword.update_keywords_from_salesforce", :user => configuration[:user], :minute => 31, :hour => 23
    cron 'update_keyword_rankings', :command => "/home/deploy/grid/current/script/runner -e production Keyword.update_keyword_rankings", :user => configuration[:user], :minute => 1, :hour => 1
    cron 'update_inbound_links', :command => "/home/deploy/grid/current/script/runner -e production SeoCampaign.update_inbound_links", :user => configuration[:user], :minute => 1, :hour => 2
    cron 'clean_up_inbound_links', :command => "/home/deploy/grid/current/script/runner -e production SeoCampaign.clean_up_inbound_links", :user => configuration[:user], :minute => 31, :hour => 2
    cron 'update_website_analyses', :command => "/home/deploy/grid/current/script/runner -e production SeoCampaign.update_website_analyses", :user => configuration[:user], :minute => 1, :hour => 3
    cron 'update_keywords_from_salesforce', :command => "/home/deploy/grid/current/script/runner -e production MapKeyword.update_keywords_from_salesforce", :user => configuration[:user], :minute => 1, :hour => 4
    cron 'update_map_rankings', :command => "/home/deploy/grid/current/script/runner -e production MapKeyword.update_map_rankings", :user => configuration[:user], :minute => 1, :hour => 5
    
    cron 'update_sem_campaign_reports_by_campaign', :command => "/home/deploy/grid/current/script/runner -e production SemCampaign.update_sem_campaign_reports_by_campaign", :user => configuration[:user], :minute => 1, :hour => 9
    cron 'update_sem_campaign_reports_by_ad', :command => "/home/deploy/grid/current/script/runner -e production SemCampaign.update_sem_campaign_reports_by_ad", :user => configuration[:user], :minute => 1, :hour => 11 

    # %w( root rails ).each do |user|
    #   mailalias user, :recipient => 'you@domain.com', :notify => exec('newaliases')
    # end

    # farm_config = <<-CONFIG
    #   MOOCOWS = 3
    #   HORSIES = 10
    # CONFIG
    # file '/etc/farm.conf', :ensure => :present, :content => farm_config

    # Logs for Rails, MySQL, and Apache are rotated by default
    # logrotate '/var/log/some_service.log', :options => %w(weekly missingok compress), :postrotate => '/etc/init.d/some_service restart'

    # Only run the following on the 'testing' stage using capistrano-ext's multistage functionality.
    # on_stage 'testing' do
    #   file '/etc/motd', :ensure => :file, :content => "Welcome to the TEST server!"
    # end
  end
  # The following line includes the 'application_packages' recipe defined above
  recipe :application_packages
end
