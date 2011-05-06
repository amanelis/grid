class BudgetInfusion < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :between, lambda { |start_date, end_date| {:conditions => ['commitment_date between ? AND ?', start_date, end_date]} }
  
  validates_numericality_of :amount, :greater_than_or_equal_to => 0.01, :message => "must be an amount $0.01 or greater"
  validates_presence_of :commitment_date
  validate :valid_date

  
  # PREDICATES

  def is_editable?
    self.channel.editable_date?(self.commitment_date)
  end
  
  
<<<<<<< HEAD
  # PRIVATE
=======
  # PRIVATE BEHAVIOR
  
>>>>>>> a628124b4126b00bf88ed0d443a7a073b33bcf0d
  private
  
    def valid_date
      errors.add(:commitment_date, "is too far in the past") if self.changed? && !self.is_editable?
    end
  
end
