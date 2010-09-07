class AdwordsAdGroup < ActiveRecord::Base
  belongs_to :google_sem_campaign
  has_many :adwords_ads, :dependent => :destroy
  has_many :adwords_keywords, :dependent => :destroy
end
