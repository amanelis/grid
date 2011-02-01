class Activity < ActiveRecord::Base
  belongs_to :activity_type, :polymorphic => true

  named_scope :previous_hours, lambda { |*args| {:conditions => ['timestamp > ?', (args.first || nil)], :order => 'timestamp DESC'} }

  named_scope :calls, :conditions => {:activity_type_type => Call.name}
  named_scope :submissions, :conditions => {:activity_type_type => Submission.name}
  
  named_scope :today, {:conditions => ['timestamp between ? AND ?', Date.today.to_time_in_current_zone.at_beginning_of_day.utc, Date.today.to_time_in_current_zone.end_of_day.utc], :order => 'timestamp DESC'}
  
   
  def is_call?
    self.activity_type.instance_of?(Call)
  end
  
  def is_submission?
    self.activity_type.instance_of?(Submission)
  end

end
