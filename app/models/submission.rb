class Submission < ActiveRecord::Base
  belongs_to :contact_form
  
  attr_accessible :from_email, :ip_address, :name, :home_address, :work_category, :work_description, :other_information, :custom1_value, :custom2_value, :custom3_value, :custom4_value, :date_requested, :time_requested, :phone_number, :created_at, :updated_at, :time_of_submission, :user_agent
  
  validates_presence_of :contact_form_id
  validates_inclusion_of :ip_address, :in => APP_CONFIG[:valid_source]

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['time_of_submission between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }

end
