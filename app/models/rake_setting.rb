class RakeSetting < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :upto, lambda { |date| {:conditions => ['start_date <= ?', date], :order => 'start_date ASC'} }
  
end
