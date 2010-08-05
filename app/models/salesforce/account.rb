class Salesforce::Account < ActiveRecord::Base
  establish_connection "sf_#{RAILS_ENV}"
end
