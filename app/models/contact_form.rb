class ContactForm < ActiveRecord::Base
  belongs_to :campaign
  has_many :submissions


  # INSTANCE BEHAVIOR

  def number_of_submissions_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.submissions.between(start_date, end_date).count
  end

end
