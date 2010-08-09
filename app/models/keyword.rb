class Keyword < ActiveRecord::Base
  belongs_to :seo_campaign
  has_many :analyses, :class_name => "KeywordAnalysis"
end
