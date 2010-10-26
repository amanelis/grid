class MapRanking < ActiveRecord::Base
  belongs_to :map_keyword

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['ranking_date between ? AND ?', start_date.to_time_in_current_zone.at_beginning_of_day.utc, end_date.to_time_in_current_zone.end_of_day.utc]} }

end
