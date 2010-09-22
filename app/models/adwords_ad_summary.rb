class AdwordsAdSummary < ActiveRecord::Base
  belongs_to :adwords_ad
  belongs_to :adwords_keyword

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['summary_date between ? AND ?', start_date, end_date]} }

end
