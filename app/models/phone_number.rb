class PhoneNumber < ActiveRecord::Base
  belongs_to :campaign
  has_many :calls
end
