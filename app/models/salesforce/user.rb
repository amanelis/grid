class Salesforce::User < ActiveRecord::Base
  establish_connection "sf_#{RAILS_ENV}"
end