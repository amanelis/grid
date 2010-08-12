set :rails_env, 'staging'

role :gateway, "stage.cityvoice.com"
role :web, "stage.cityvoice.com"                          # Your HTTP server, Apache/etc
role :app, "stage.cityvoice.com"                          # This may be the same as your `Web` server
role :db,  "stage.cityvoice.com", :primary => true        # This is where Rails migrations will run
#role :db,  "your slave db-server here"