class ContactForm < ActiveRecord::Base
  belongs_to :campaign
  has_many :submissions, :dependent => :destroy
  WUFOO_API_KEY = '9FTI-TCG8-BSEE-RFUV'
  WUFOO_POST_KEY = 'hM7iVJ7tjf3Q7puc4f5FfxOJqDDr4woIxF0s68UU7Eo='
  
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

  def create_wufoo_form
    wufoo = WuParty.new("cityvoice", "9FTI-TCG8-BSEE-RFUV") 
    w
    
    
    
    
    
  end
  
  
end
