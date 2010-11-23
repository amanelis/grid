class Submission < ActiveRecord::Base
  include ActivityTypeMixin

  belongs_to :contact_form
  
  attr_accessible :contact_form_id, :from_email, :ip_address, :name, :home_address, :work_category, :work_description, :other_information, :custom1_value, :custom2_value, :custom3_value, :custom4_value, :date_requested, :time_requested, :phone_number, :user_agent
  
  PENDING = 'pending'
  SPAM = 'spam'
  FEEDBACK = 'feedback'
  OTHER = 'other'
  LEAD = 'lead'
  FOLLOWUP = 'followup'

  ALL_REVIEW_STATUS_OPTIONS = [PENDING, SPAM, FEEDBACK, OTHER, LEAD, FOLLOWUP]
  UNIQUE_REVIEW_STATUS_OPTIONS = [['Pending', PENDING], ['Lead', LEAD], ['Spam', SPAM], ['Feedback', FEEDBACK], ['Other', OTHER]].to_ordered_hash
  DUPLICATE_STATUS_OPTIONS = [['Pending', PENDING], ['Followup', FOLLOWUP], ['Spam', SPAM], ['Feedback', FEEDBACK], ['Other', OTHER]].to_ordered_hash

  DAYS_UNTIL_UNIQUE = 15.days
  
  validates_inclusion_of :review_status, :in => ALL_REVIEW_STATUS_OPTIONS
  validates_presence_of :contact_form_id

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['time_of_submission between ? AND ?', start_date.to_time_in_current_zone.at_beginning_of_day.utc, end_date.to_time_in_current_zone.end_of_day.utc]} }
  named_scope :previous_hours, lambda { |*args| {:conditions => ['time_of_submission > ?', (args.first || nil)], :order => 'time_of_submission DESC'} }
  
  named_scope :lead, {
    :select => "submissions.*",
    :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'", 
    :conditions => ['activities.duplicate = FALSE AND (activities.review_status = ? OR activities.review_status = ?)', PENDING, LEAD]
  }

  named_scope :non_spam, {
    :select => "submissions.*",
    :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'", 
    :conditions => "activities.review_status <> 'spam'"
  }

  named_scope :pending, {
    :select => "submissions.*",
    :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'", 
    :conditions => ['activities.review_status = ?', PENDING]
  }

  named_scope :reviewed, {
    :select => "submissions.*",
    :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'", 
    :conditions => ['activities.review_status <> ?', PENDING]
  }


  # INSTANCE BEHAVIOR
  
  def initialize_specifics(attributes={})
    self.review_status = PENDING
    self.review_status = SPAM if self.is_spam?
  end
  
  def update_if_duplicate
    self.update_attribute(:duplicate, true) if self.duplicate_submissions_present?
  end

  def duplicate_submissions_present?
    self.submissions_from_same_email_or_phone_number_over_past_days_until_unique.present?
  end
  
  def submissions_from_same_email_or_phone_number_over_past_days_until_unique
    Submission.find(:all,
              :joins => "INNER JOIN activities ON submissions.id = activities.activity_type_id AND activities.activity_type_type = 'Submission'",
              :conditions => ['submissions.id <> ? AND contact_form_id = ? AND activities.review_status IN (?) AND (time_of_submission between ? AND ?)', self.id, self.contact_form_id, [PENDING, SPAM, FEEDBACK, OTHER, LEAD, FOLLOWUP], self.time_of_submission - 30.days, self.time_of_submission],
              :order => 'time_of_submission DESC').select { |submission| self.has_same_email_or_phone_number?(submission) }
  end
  
  def has_same_email_or_phone_number?(submission)
    self.has_same_email?(submission) || self.has_same_phone_number?(submission)
  end
  
  def has_same_email?(submission)
    Utilities.is_valid_email_address?(self.from_email) && Utilities.is_valid_email_address?(submission.from_email) ? self.from_email == submission.from_email : false
  end

  def has_same_phone_number?(submission)
    Utilities.is_valid_phone_number?(self.phone_number) && Utilities.is_valid_phone_number?(submission.phone_number) ? self.phone_number.gsub(/\D/, '') == submission.phone_number.gsub(/\D/, '') : false
  end
  
  def duplicate_submission_chain(chain = [])
    (submissions = self.submissions_from_same_email_or_phone_number_over_past_days_until_unique).empty? ? chain << self : submissions.pop.duplicate_submission_chain(chain.concat(submissions))
  end
  
  def time_of_submission= the_time_of_submission
    self[:time_of_submission] = the_time_of_submission
    self.timestamp = the_time_of_submission
  end
  
  def is_spam?
    return true if self.phone_number =~ /1010101010/
    return true if self.work_description =~ /http:/i
    return true if self.work_description =~ /\bporn\b/i
    return true if self.work_description =~ /\bviagra\b/i
    return true if self.work_description =~ /\bsex\b/i
    return true if self.work_description =~ /\bsexual\b/i
    return true if self.work_description =~ /\banime\b/i
    return true if self.work_description =~ /\bsearch\s*engine/i
    return true if self.work_description =~ /\binternet\s*marketing\b/i
    return true if self.work_description =~ /\bincrease\s*traffic\b/i
    return true if self.work_description =~ /\bonline\s*leads\b/i
    return true if self.work_description =~ /\bmicro-ticket\s*leasing\b/i
    return true if self.work_description =~ /\bwhite-hat\b/i
    return true if self.work_description =~ /\bSEO\b/
    return true if self.work_description =~ /\bSEM\b/
    return true if self.work_description =~ /\bno\s*application\s*fee\b/i
    return true if self.work_description =~ /\bdear\s*business\s*owner\b/i
    return true if self.work_description =~ /\bdear\s*head\b/i
    return true if self.work_description =~ /\brelevant\s*traffic\b/i
    return true if self.work_description =~ /\bгруди\b/i
    return true if self.work_description =~ /\bсисечки\b/i
    return true if self.work_description =~ /\bпроституток\b/i
    return true if self.work_description =~ /\bтелок\b/i
    return true if self.work_description =~ /\bблондиночк\b/i
    false
  end
  
  def review_status_spam?
    self.review_status == SPAM
  end

  def review_status_options
    self.duplicate? ? DUPLICATE_STATUS_OPTIONS : UNIQUE_REVIEW_STATUS_OPTIONS
  end
  
end
