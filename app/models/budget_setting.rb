class BudgetSetting < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :upto, lambda { |date| {:conditions => ['start_date <= ?', date], :order => 'start_date ASC, updated_at ASC'} }
  
  validates_numericality_of :amount, :greater_than_or_equal_to => 0.0, :message => "must be an amount $0.00 or greater"
  validates_presence_of :start_date
  validate :valid_date
  
  
  # PREDICATES

  def is_editable?
    self.channel.editable_date?(self.start_date)
  end
  
  
  # PRIVATE
  private
  
    def valid_date
      errors.add(:start_date, "is too far in the past") if self.changed? && !self.is_editable?
    end
  
end
