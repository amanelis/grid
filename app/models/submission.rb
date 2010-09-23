class Submission < ActiveRecord::Base
  belongs_to :contact_form
  
  attr_accessible :contact_form_id, :from_email, :ip_address, :name, :home_address, :work_category, :work_description, :other_information, :custom1_value, :custom2_value, :custom3_value, :custom4_value, :date_requested, :time_requested, :phone_number, :user_agent
  
  PENDING = 'pending'
  SPAM = 'spam'
  FEEDBACK = 'feedback'
  OTHER = 'other'
  LEAD = 'lead'

  REVIEW_STATUS_OPTIONS = [['Pending', PENDING], ['Spam', SPAM], ['Feedback', FEEDBACK], ['Other', OTHER], ['Lead', LEAD]].to_ordered_hash

  validates_inclusion_of :review_status, :in => REVIEW_STATUS_OPTIONS.values
  validates_presence_of :contact_form_id

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['time_of_submission between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }
  named_scope :previous_hours, lambda { |number| {:conditions => ['time_of_submission between ? AND ?', Time.now.utc - number.hours, Time.now]} }

  def timestamp
    self.time_of_submission
  end

  def initialize(attributes={})
    super(attributes)
    self.review_status = PENDING
    self
  end

end
