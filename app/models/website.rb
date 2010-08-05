class Website < ActiveRecord::Base
  has_and_belongs_to_many :campaigns
  has_many :website_visits
end
