set :rails_env, 'development'
set :branch, 'develop'

role :gateway, "localhost:3000"
role :web, "localhost:3000"                          # Your HTTP server, Apache/etc
role :app, "localhost:3000"                          # This may be the same as your `Web` server
role :db,  "localhost:3000", :primary => true        # This is where Rails migrations will run
#role :db,  "your slave db-server here"