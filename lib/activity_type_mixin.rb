module ActivityTypeMixin

  def self.included(base)
    base.class_eval do
      has_one :activity, :as => :activity_type, :dependent => :destroy
      delegate :review_status, :review_status=,:timestamp, :timestamp=, :duplicate, :duplicate?, :duplicate=, :description, :description=, :revenue, :revenue=, :to => :activity
      accepts_nested_attributes_for :activity
    end
  end
  
  # INITIALIZATION
  
  def after_initialize
    return unless self.new_record?
    self.activity ||= Activity.new
    self.activity.activity_type ||= self
    self.initialize_thyself
  end
  
  
  # INSTANCE BEHAVIOR
  
  def time_zone
    self.campaign.time_zone
  end

end