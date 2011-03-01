class BasicChannel < ActiveRecord::Base
  belongs_to :account
  has_many :basic_campaigns
end
