class Submission < ActiveRecord::Base
  include ActivityTypeMixin

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
  named_scope :previous_hours, lambda { |*args| {:conditions => ['time_of_submission > ?', (args.first || nil)], :order => 'time_of_submission DESC'} }
  
  named_scope :non_spam, {
    :select => "submissions.*",
    :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'", 
    :conditions => "activities.review_status <> 'spam'"
  }
  

  def initial_review_status
    PENDING
  end

  def time_of_submission= the_time_of_submission
    self[:time_of_submission] = the_time_of_submission
    self.timestamp = the_time_of_submission
  end
  
  def is_spam?
    return true if self.phone_number =~ /123456/
    return true if self.work_description =~ /http:/i
    return true if self.work_description =~ /search.*engine/i
    return true if self.work_description =~ /internet.* marketing/i
    false
  end
  
  def set_review_status_spam
    self.review_status = SPAM
  end
  
  def review_status_spam?
    self.review_status == SPAM
  end
  
end
