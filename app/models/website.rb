class Website < ActiveRecord::Base
  belongs_to :campaign
  has_many :website_visits  
end
