class ContactForm < ActiveRecord::Base
  belongs_to :campaign
  has_many :submissions, :dependent => :destroy


  # INSTANCE BEHAVIOR

  def number_of_lead_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.lead.between(start_date, end_date).count
  end

  def number_of_all_submissions_between(start_date = Date.yesterday, end_date = Date.yesterday)
    self.submissions.between(start_date, end_date).count
  end

  def number_of_lead_submissions_by_date
    self.submissions.lead.count(:group => "date(time_of_submission)", :order =>"time_of_submission ASC").inject({}) {|data, (key, value)| data[key.to_date] = {:submission => value} ; data}
  end
  
  def inactive?
    self.active? ? false : true
  end

end
