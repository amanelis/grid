class MapRanking < ActiveRecord::Base
  belongs_to :map_keyword

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['ranking_date between ? AND ?', start_date.to_time.in_time_zone.at_beginning_of_day, end_date.to_time.in_time_zone.end_of_day]} }

end
