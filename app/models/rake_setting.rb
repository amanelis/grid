class RakeSetting < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :upto, lambda { |date| {:conditions => ['start_date <= ?', date], :order => 'start_date ASC'} }
  
  validates_numericality_of :percentage, :only_integer => true, :greater_than_or_equal_to => 0, :message => "must be an integer zero or greater"
  validates_presence_of :start_date
  
end
