class Account < ActiveRecord::Base
  has_many :campaigns
end
