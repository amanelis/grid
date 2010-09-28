class Activity < ActiveRecord::Base
  belongs_to :activity_type, :polymorphic => true

  named_scope :previous_hours, lambda { |*args| {:conditions => ['timestamp > ?', (args.first || nil)], :order => 'timestamp DESC'} }
  
  def is_call?
    self.activity_type.instance_of?(Call)
  end
  
  def is_submission?
    self.activity_type.instance_of?(Submission)
  end

end
