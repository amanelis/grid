class KeywordRanking < ActiveRecord::Base
  belongs_to :keyword

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['created_at between ? AND ?', start_date.to_time_in_current_zone.at_beginning_of_day.utc, end_date.to_time_in_current_zone.end_of_day.utc]} }

end
