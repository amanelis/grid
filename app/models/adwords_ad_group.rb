class AdwordsAdGroup < ActiveRecord::Base
  belongs_to :google_sem_campaign
  has_many :adwords_ads
  has_many :adwords_keywords
end
