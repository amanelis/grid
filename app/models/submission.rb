class Submission < ActiveRecord::Base
  belongs_to :contact_form
  validates_presence_of :contact_form_id
  validates_inclusion_of :ip_address, :in => APP_CONFIG[:valid_source]

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['time_of_submission between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }

end
