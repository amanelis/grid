# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

User.create!(:email => "admin@cv.com", :password =>"admin",   :password_confirmation => "admin", :admin => 1)
User.create!(:email => "user@cv.com",  :password =>"user",    :password_confirmation => "user",  :admin => 0)
User.create!(:email => "guw@cv.com",   :password => "guw123", :password_confirmation => "guw123")
User.create!(:email => "gur@cv.com",   :password => "gur123", :password_confirmation => "gur123")
User.create!(:email => "auw@cv.com",   :password => "auw123", :password_confirmation => "auw123")
User.create!(:email => "aur@cv.com",   :password => "aur123", :password_confirmation => "aur123")