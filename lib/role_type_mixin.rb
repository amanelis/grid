module RoleTypeMixin

  def self.included(base)
    base.class_eval do
      has_one :role, :as => :role_type, :dependent => :destroy
      delegate :review_status, :review_status=,:timestamp, :timestamp=, :duplicate, :duplicate?, :duplicate=, :to => :activity
      accepts_nested_attributes_for :role

      def initialize(attributes={})
        super(attributes)
        self.role = Role.new
        # self.initialize_specifics(attributes)
        self
      end

    end
  end

end