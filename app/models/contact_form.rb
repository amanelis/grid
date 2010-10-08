class ContactForm < ActiveRecord::Base
  belongs_to :campaign
  has_many :submissions, :dependent => :destroy


  # INSTANCE BEHAVIOR

  def number_of_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.non_spam.between(start_date, end_date).count
  end

  def number_of_submissions_by_date
    self.submissions.non_spam.count(:group => "date(time_of_submission)", :order =>"time_of_submission ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:submission => value} ; data}
  end

end
