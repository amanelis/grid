# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

User.create!(:email => "admin@cityvoice.com", :password =>"admin", :password_confirmation => "admin", :admin => 1)
User.create!(:email => "user@cityvoice.com", :password =>"user", :password_confirmation => "user", :admin => 0)