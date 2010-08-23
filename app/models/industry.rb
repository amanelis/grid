class Industry < ActiveRecord::Base
  has_and_belongs_to_many :campaigns
  has_many :industry_keywords
end
