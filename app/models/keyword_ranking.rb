class KeywordRanking < ActiveRecord::Base
  belongs_to :keyword

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['created_at between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }

end
