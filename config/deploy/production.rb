set :rails_env, 'production'
set :branch, 'master'

role :gateway, "grid.cityvoice.com"
role :web, "grid.cityvoice.com"                          # Your HTTP server, Apache/etc
role :app, "grid.cityvoice.com"                          # This may be the same as your `Web` server
role :db,  "grid-db.cityvoice.com", :primary => true        # This is where Rails migrations will run
#role :db,  "your slave db-server here"