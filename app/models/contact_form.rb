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
    
  end
  
  def get_form_text()
      form_text = "<form action=\"http://grid.cityvoice.com/submission\" method=\"POST\" name=\"Form1\" onSubmit=\"return checkform()\"><input type=hidden id=\"contact_form_id\" name=\"submission[contact_form_id]\" value=\"#{self.id}\"> <input type=hidden name=\"submission[retURL]\" value=\"#{self.return_url}\"><table border=\"0\" width=\"100%\"><tr><td>*Fields Are Required</td></tr>"

      form_text += "<tr><td width=\"164\"><p align=\"right\"><label for=\"first_name\">First Name</label></td><td><input id=\"first_name\" maxlength=\"40\" name=\"submission[name][]\" size=\"20\" type=\"text\"/></td></tr><tr><td width=\"164\"><p align=\"right\"><label for=\"last_name\">Last Name</label></td><td><input id=\"last_name\" maxlength=\"40\" name=\"submission[name][]\" size=\"20\" type=\"text\"/></td></tr>" if self.need_name == true
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"address\">Address</label></td><td><input id=\"home_address\" maxlength=\"40\" name=\"submission[home_address][]\" size=\"20\" type=\"text\"/></td></tr><tr><td width=\"164\" align=\"right\"><label for=\"address\">City</label></td><td><input id=\"city\" maxlength=\"40\" name=\"submission[home_address][]\" size=\"20\" type=\"text\"/></td></tr><tr><td width=\"164\" align=\"right\"><label for=\"time\">State</label></td><td><input id=\"state\" maxlength=\"40\" name=\"submission[home_address][]\" size=\"20\" type=\"text\"/></td></tr><tr><td width=\"164\" align=\"right\"><label for=\"address\">Zip</label></td><td><input id=\"zip_code\" maxlength=\"40\" name=\"submission[home_address][]\" size=\"20\" type=\"text\"/></td></tr>" if self.need_address == true
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"phone\">Phone #</label></td><td><input id=\"phone_number\" maxlength=\"40\" name=\"submission[phone_number]\" size=\"20\" type=\"text\"/></td></tr>" if self.need_phone == true          
      form_text += "<tr><td width=\"164\"><p align=\"right\"><label for=\"email\">Email</label></td><td><input id=\"from_email\" maxlength=\"80\" name=\"submission[from_email]\" size=\"20\" type=\"text\"/></td></tr>" if self.need_email == true           
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"custom2\">Work Request</label></td><td><select id=\"work_category\" name=\"submission[work_category]\"><option value=\"\"></option><option value=\"Category 1\">Category 1</option><option value=\"Category 2\">Category 2</option><option value=\"Category 3\">Category 3</option></select></td></tr>" if self.work_category == true            

      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"work_description\">Description of problem or concerns</label></td><td><textarea id=\"work_description\" name=\"submission[work_description]\"></textarea></td></tr>" if self.work_description == true   
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"work_date\">Preferred Appointment Date</label></td><td><input id=\"date_requested\" size=\"12\" name=\"submission[date_requested]\" type=\"text\"/></td></tr>" if self.date_requested == true               
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"time\">Preferred Appointment Date</label></td><td><select id=\"time_requested\" name=\"submission[time_requested]\"><option value=\"Any\">Any</option><option value=\"ASAP\">ASAP</option><option value=\"8 AM\">8 AM</option><option value=\"9 AM\">9 AM</option><option value=\"10 AM\">10 AM</option><option value=\"Other\">Other</option></select></td></tr>" if self.time_requested == true         
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"other_information\">Questions or Comments</label></td><td><textarea name=\"submission[other_information]\"></textarea></td></tr>" if self.other_information == true         
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"time\">#{self.custom1_text}</label></td><td><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom1_value]\" size=\"20\" type=\"text\"/></td></tr>" if self.custom1_text.present?
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"time\">#{self.custom2_text}</label></td><td><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom2_value]\" size=\"20\" type=\"text\"/></td></tr>" if self.custom2_text.present?
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"time\">#{self.custom3_text}</label></td><td><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom3_value]\" size=\"20\" type=\"text\"/></td></tr>" if self.custom3_text.present?
      form_text += "<tr><td width=\"164\" align=\"right\"><label for=\"time\">#{self.custom4_text}</label></td><td><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom4_value]\" size=\"20\" type=\"text\"/></td></tr>" if self.custom4_text.present?
      form_text += "<tr><td width=\"164\">&nbsp;</td><td><input type=\"submit\" name=\"submit\" value=\"Submit Request\" onclick=\"return checkform()\"></td></tr></table></form>"
      form_text
    
  end
  
  
end
