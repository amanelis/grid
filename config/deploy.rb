require 'capistrano/ext/multistage'

set :default_stage, "development"
set :stages, %w(production staging development)

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

#before "deploy", "delayed_job:stop"
#after "deploy:finalize_update", "delayed_job:start"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

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