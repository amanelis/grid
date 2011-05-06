class RakeSetting < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :upto, lambda { |date| {:conditions => ['start_date <= ?', date], :order => 'start_date ASC, updated_at ASC'} }
  
  validates_numericality_of :percentage, :only_integer => true, :greater_than_or_equal_to => 0, :message => "must be an integer zero or greater"
  validates_presence_of :start_date
  validate :valid_date
  
  
  # PREDICATES

  def is_editable?
    self.channel.editable_date?(self.start_date)
  end


  # PRIVATE BEHAVIOR

  private
  
  def valid_date
    errors.add(:start_date, "is too far in the past") if self.changed? && !self.is_editable?
  end
  
end
