require 'capistrano/ext/multistage'

set :default_stage, "development"
set :stages, %w(production staging development)

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

before "deploy", "delayed_job:stop"
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


namespace :delayed_job do
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/delayed_job -n 3 start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/delayed_job -n 3 restart"
  end
end