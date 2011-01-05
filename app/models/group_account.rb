class GroupAccount < ActiveRecord::Base
  has_many :accounts

  validates_uniqueness_of :name, :case_sensitive => false
  
end
