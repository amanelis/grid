class AdwordsAdSummary < ActiveRecord::Base
  belongs_to :adwords_ad

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['summary_date between ? AND ?', start_date, end_date]} }

end
