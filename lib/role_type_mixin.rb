module RoleTypeMixin

  def self.included(base)
    base.class_eval do
      has_one :role, :as => :role_type, :dependent => :destroy
      delegate :user, :user=, :to => :role
      accepts_nested_attributes_for :role

      def initialize(attributes={})
        super(attributes)
        self.role = Role.new
        self.role.role_type = self
        # self.initialize_specifics(attributes)
        self
      end

    end
  end

end