module ActivityTypeMixin

  def self.included(base)
    base.class_eval do
      has_one :activity, :as => :activity_type, :dependent => :destroy
      delegate :review_status, :review_status=,:timestamp, :timestamp=, :to => :activity
      accepts_nested_attributes_for :activity

      def initialize(attributes={})
        super(attributes)
        self.activity = Activity.new
        self.initialize_specifics(attributes)
        self
      end

    end
  end

end