module RoleTypeMixin

  def self.included(base)
    base.class_eval do
      has_one :role, :as => :role_type, :dependent => :destroy
      delegate :user, :user=, :to => :role
      accepts_nested_attributes_for :role
    end
  end
  
  # INITIALIZATION
  
  def after_initialize
    return unless self.new_record?
    self.role ||= Role.new
    self.role.role_type ||= self
  end

end