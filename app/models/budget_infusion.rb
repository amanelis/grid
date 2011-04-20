class BudgetInfusion < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :between, lambda { |start_date, end_date| {:conditions => ['commitment_date between ? AND ?', start_date, end_date]} }
  
  validates_numericality_of :amount, :greater_than_or_equal_to => 0.01, :message => "must be an amount $0.01 or greater"
  validates_presence_of :commitment_date
  
end
