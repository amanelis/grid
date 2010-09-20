set :rails_env, 'staging'
set :branch, 'staging'

role :gateway, "staging.cityvoice.com"
role :web, "staging.cityvoice.com"                          # Your HTTP server, Apache/etc
role :app, "staging.cityvoice.com"                          # This may be the same as your `Web` server
role :db,  "staging.cityvoice.com", :primary => true        # This is where Rails migrations will run
#role :db,  "your slave db-server here"