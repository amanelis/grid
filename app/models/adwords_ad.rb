class AdwordsAd < ActiveRecord::Base
  belongs_to :adwords_ad_group
  has_many :adwords_ad_summaries, :dependent => :destroy
end
