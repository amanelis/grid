require "#{File.dirname(__FILE__)}/../../vendor/plugins/moonshine/lib/moonshine.rb"
class DatabaseManifest < Moonshine::Manifest::Rails
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

  # The default_stack recipe install Rails, Apache, Passenger, MySQL,
  # Postfix, Cron, and NTP. To customize the stack, see lib/moonshine/manifest/rails.rb
  #recipe :default_stack
  recipe :mysql_server, :mysql_gem, :mysql_database, :mysql_user, :mysql_fixup_debian_start,
    :rails_rake_environment, :rails_gems, :rails_directories, :rails_bootstrap, :rails_migrations, :rails_logrotate,
    :ntp, :time_zone, :postfix, :cron_packages, :motd, :security_updates

  # Add your application's custom requirements here
  
  configure({    
    :mysql => { 
      :version => "5.1",
      :long_query_time => "3",
      :log_bin => "mysql-bin",
      :server_id => "1",
      :innodb_flush_log_at_trx_commit => "1",
      :auto_increment_increment => "1",
      :query_cache_limit => "64M",
      :tmpdir => "/dev/shm",
      :max_heap_table_size => "256M",
      :tmp_table_size => "256M",
      :max_connections => "250",
      :extra => "bind-address = 173.203.219.#{deploy_stage == 'production' ? 85 : 193 }"
       },   
       
    :iptables => { :rules => [
        '-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT',
        '-A INPUT -p icmp -j ACCEPT',
        '-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT',
        '-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT',
        '-A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT',
        '-A INPUT -s 127.0.0.1 -j ACCEPT'
      ]}

  })

  plugin :iptables
  plugin :ssh

  recipe :iptables
  recipe :ssh
  
  plugin :monit
  recipe :monit
  
  def application_packages
    # If you've already told Moonshine about a package required by a gem with
    # :apt_gems in <tt>moonshine.yml</tt> you do not need to include it here.
    # package 'some_native_package', :ensure => :installed
    
    # some_rake_task = "/usr/bin/rake -f #{configuration[:deploy_to]}/current/Rakefile custom:task RAILS_ENV=#{ENV['RAILS_ENV']}"
    # cron 'custom:task', :command => some_rake_task, :user => configuration[:user], :minute => 0, :hour => 0
    #   cron 'Update_All_Feeds',
    #     :command => "/home/deploy/philtro/current/script/runner -e production Feed.pull",
    #     :user => configuration[:user],
    #     :hour => 3
    
    # %w( root rails ).each do |user|
    #   mailalias user, :recipient => 'you@domain.com'
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
    #   file '/etc/motd', :ensure => file, :content => "Welcome to the TEST server!"
    # end
  end
  # The following line includes the 'application_packages' recipe defined above
  recipe :application_packages
end