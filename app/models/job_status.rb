class JobStatus < ActiveRecord::Base

  RUNNING = "Running"
  FINISHED_NO_ERRORS = "Finished No Errors"
  FINISHED_WITH_ERRORS = "Finished With Errors"

  named_scope :running, :conditions => {:status => RUNNING}
  named_scope :finished_no_errors, :conditions => {:status => FINISHED_NO_ERRORS}
  named_scope :finished_with_errors, :conditions => {:status => FINISHED_WITH_ERRORS}

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['start_time between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }
  named_scope :today, {:conditions => ['start_time between ? AND ?', Date.today.to_time.utc.at_beginning_of_day, Date.today.to_time.utc.end_of_day]}
  named_scope :yesterday, {:conditions => ['start_time between ? AND ?', Date.yesterday.to_time.utc.at_beginning_of_day, Date.yesterday.to_time.utc.end_of_day]}
  named_scope :past_week, {:conditions => ['start_time between ? AND ?', (Date.today - 1.week).to_time.utc.at_beginning_of_day, Date.today.to_time.utc.end_of_day]}

  def initialize(parms)
    super(parms)
    self.status = RUNNING
    self.start_time = DateTime.now
  end

  def finish_with_no_errors
    self.finish(FINISHED_NO_ERRORS)
  end

  def finish_with_errors(the_exception)
    self.error_message = the_exception.to_s + "\n" + the_exception.backtrace.join("\n")
    self.finish(FINISHED_WITH_ERRORS)
  end


  protected

  def finish(the_status)
    self.status = the_status
    self.end_time = DateTime.now
    self.save!
  end

end
