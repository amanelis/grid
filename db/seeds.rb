# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

User.create(:email => 'admin@cv.com', 
            :crypted_password => '097ae996780485f8235540f02dec02e5ecca12aabd82d8990c5e25c337691faf96bfc62c412c9c955b46a46d1078c137a97c427c4a4d3a59a7a8c9c259cd9f4f',
            :password_salt => 'e5oQEy5UCBTyo2YPXpKy',
            :persistence_token => '543177e501dbbe8e31ce3c9f5a260138f0f9613214d56ba7f5d40a469d181c622683b1500ca38e0fe3ae4100ac4e6be5dec4540d67c59def0588d535cac03823',
            :single_access_token => 'BC4Kq8vXAnNyvLixsEu',
            :perishable_token => 'qUI6sIizwdf2aM0IIxCq',
            :admin => 1,
            :login_count => 0,
            :last_request_at => '2011-02-21 18:54:10')
