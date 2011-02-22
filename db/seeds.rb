# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

User.create!(:email => "admin@cityvoice.com", :password =>"admin", :password_confirmation => "adminuser", :admin => 1)

=begin
User.create!(:email => 'adminuser@cv.com', 
            :crypted_password     => 'db95630f3ab0cfcc801a9e8716ad80b5c124f3c1035f1467706e02306aed84f7f066ff8790a88403b3a7b16b474a0ed3510a724e9af4d90299d9855f207f33fd',
            :password_salt        => '2XiHHH3523nJLpZmAUZT',
            :persistence_token    => '2c075021d5fa9d8a040949ec9a84dd1fc956150df7141590ffcb729e99510b89b717a0bc24ed904e0a1baf7ef53a9d82b5ee2b033f84a4b56f12c28bd6d8fd81',
            :single_access_token  => 'BC4Kq8vXAnNyvLixsEu',
            :perishable_token     => 'nlsDdrvdYVg3rZiix7Zf',
            :admin => 1,
            :login_count => 0,
            :last_request_at => '2011-02-21 18:54:10')
=end