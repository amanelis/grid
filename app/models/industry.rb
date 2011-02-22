class Industry < ActiveRecord::Base
  has_and_belongs_to_many :campaigns, :uniq => true
  has_many :industry_keywords, :dependent => :destroy
end
