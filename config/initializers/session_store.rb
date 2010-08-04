# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_grid_session',
  :secret      => '913e0d2b00ffb138e19d35687a9748061396bffd21bc9ac8c3505d786f1f05c3ef04ba1fbd675c88a675d932df2d8c3daa933eee41888341ba64d13e72756b4d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
