class Activity < ActiveRecord::Base
  belongs_to :activity_type, :polymorphic => true

  named_scope :previous_hours, lambda { |*args| {:conditions => ['timestamp > ?', (args.first || nil)], :order => 'timestamp DESC'} }

end
