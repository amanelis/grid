class BasicChannel < ActiveRecord::Base
  belongs_to :account
  has_many :basic_campaigns
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :scope => "account_id"
end
