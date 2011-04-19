class BudgetInfusion < ActiveRecord::Base
  belongs_to :channel
  
  named_scope :between, lambda { |start_date, end_date| {:conditions => ['commitment_date between ? AND ?', start_date, end_date]} }
  
end
