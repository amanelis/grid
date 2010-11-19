require 'capistrano/ext/multistage'

set :default_stage, "development"
set :stages, %w(production staging development)

set :scm, :git
# Or: "accurev", "bzr", "cvs", "darcs", "git", "mercurial", "perforce", "subversion" or "none"

before "deploy", "delayed_job:stop"
before "deploy:cleanup", "pdfkit:ensure_wkhtmltopdf_installed"
after "deploy:cleanup", "delayed_job:start"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :moonshine do
  desc 'Apply the Moonshine manifest for this application, customized for CityVoice use.'
  task :apply do
    on_rollback do
      run "cd #{latest_release} && RAILS_ENV=#{fetch(:rails_env, 'production')} rake --trace environment"
    end
    parallel do |session|
      #session.when "in?(:web)", "#{sudo} RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{ENV['DEPLOY_STAGE']||fetch(:stage,'undefined')} RAILS_ENV=#{fetch(:rails_env, 'production')} shadow_puppet #{latest_release}/app/manifests/#{fetch(:moonshine_manifest, 'web_manifest')}.rb"
      session.when "in?(:web)", "#{sudo} RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{ENV['DEPLOY_STAGE']||fetch(:stage,'undefined')} RAILS_ENV=#{fetch(:rails_env, 'production')} shadow_puppet #{latest_release}/app/manifests/application_manifest.rb"
      session.when "in?(:app)", "#{sudo} RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{ENV['DEPLOY_STAGE']||fetch(:stage,'undefined')} RAILS_ENV=#{fetch(:rails_env, 'production')} shadow_puppet #{latest_release}/app/manifests/application_manifest.rb"
      session.when "in?(:db)", "#{sudo} RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{ENV['DEPLOY_STAGE']||fetch(:stage,'undefined')} RAILS_ENV=#{fetch(:rails_env, 'production')} shadow_puppet #{latest_release}/app/manifests/database_manifest.rb"
      #session.when "in?(:worker)", "#{sudo} RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{ENV['DEPLOY_STAGE']||fetch(:stage,'undefined')} RAILS_ENV=#{fetch(:rails_env, 'production')} shadow_puppet #{latest_release}/app/manifests/worker_manifest.rb"
    end
    sudo "touch /var/log/moonshine_rake.log && cat /var/log/moonshine_rake.log"
  end
end

namespace :pdfkit do
  desc "Brute force attempt at ensuring that wkhtmltopdf is installed on the target machines."
  task :ensure_wkhtmltopdf_installed, :roles => :app do
    #run "sudo pdfkit --install-wkhtmltopdf"
    require 'open-uri'
    
    if File.exists?("/usr/local/bin/wkhtmltopdf")
      puts "wkhtmltopdf is already installed -- skipping"
    else
      puts "Installing wkhtmltopdf binaries to /usr/local/bin with ARCHITECTURE=i386"
      Dir.chdir '/tmp'
    
      puts "Cleaning up any existing wkhtmltopdf installation..."
      run "sudo rm -rf /usr/local/bin/wkhtmltopdf*"
      run "sudo rm -rf /tmp/wkhtmltopdf*"
    
      puts "Downloading latest wkhtmltopdf binary..."
      #page = open("http://code.google.com/p/wkhtmltopdf/downloads/list").read
      #download = page.match(/href=".*name=(.*wkhtmltopdf-.*i386.*?)&/) || raise("File not found..")
      #download = download[1]
      
      download = "wkhtmltopdf-0.9.9-static-i386.tar.bz2"
      url = "http://wkhtmltopdf.googlecode.com/files/#{download}"
      
      puts "Downloading #{download} from #{url}"

      run "curl #{url} > #{download}"
    
      puts "Installing #{download} to /usr/local/bin"
      if download =~ /.tar.bz2$/
        run "tar xjvf #{download}"
        run "sudo mv wkhtmltopdf-i386 /usr/local/bin"
      elsif download =~ /.tar.lzma$/
        run "tar --lzma -xf #{download}"
        run "sudo mv wkhtmltopdf-i386 /usr/local/bin"
      else
        run "sudo mv #{download} /usr/local/bin"
      end
      run "sudo mv /usr/local/bin/wkhtmltopdf-i386 /usr/local/bin/wkhtmltopdf"
      run "sudo chmod +x /usr/local/bin/wkhtmltopdf"
    end
  end
end

namespace :delayed_job do
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 3 start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 3 restart"
  end
end