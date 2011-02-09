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

  def create_wufoo_form
    wufoo = WuParty.new("cityvoice", "9FTI-TCG8-BSEE-RFUV") 
  end
  
  def get_form_text
      form_text = "<form action=\"http://grid.cityvoice.com/submission\" method=\"POST\" name=\"Form1\" onSubmit=\"return checkform()\"><input type=hidden id=\"contact_form_id\" name=\"submission[contact_form_id]\" value=\"#{self.id}\"> <input type=hidden name=\"submission[retURL]\" value=\"#{self.return_url}\">*Fields Are Required</br></br>"
      form_text += "<p align=\"center\"><label for=\"first_name\">Name</label><input id=\"first_name\" maxlength=\"40\" name=\"submission[name]\" size=\"20\" type=\"text\"/></br>" if self.need_name == true
      form_text += "<p align=\"center\"><label for=\"address\">Address</label><input id=\"home_address\" maxlength=\"40\" name=\"submission[home_address][]\" size=\"20\" type=\"text\"/><p align=\"right\"><label for=\"address\">City</label><input id=\"city\" maxlength=\"40\" name=\"submission[home_address]\" size=\"40\" type=\"text\"/></br>" if self.need_address == true
      form_text += "<p align=\"center\"><label for=\"phone\">Phone #</label><input id=\"phone_number\" maxlength=\"40\" name=\"submission[phone_number]\" size=\"20\" type=\"text\"/></br>" if self.need_phone == true          
      form_text += "<p align=\"center\"><label for=\"email\">Email</label><input id=\"from_email\" maxlength=\"80\" name=\"submission[from_email]\" size=\"20\" type=\"text\"/></br>" if self.need_email == true           
      form_text += "<p align=\"center\"><label for=\"custom2\">Work Request</label><select id=\"work_category\" name=\"submission[work_category]\"><option value=\"\"></option><option value=\"Category 1\">Category 1</option><option value=\"Category 2\">Category 2</option><option value=\"Category 3\">Category 3</option></select></br>" if self.work_category == true            
      form_text += "<p align=\"center\"><label for=\"work_description\">Description of problem or concerns</label><textarea id=\"work_description\" name=\"submission[work_description]\"></textarea></br>" if self.work_description == true   
      form_text += "<p align=\"center\"><label for=\"work_date\">Preferred Appointment Date</label><input id=\"date_requested\" size=\"12\" name=\"submission[date_requested]\" type=\"text\"/></br>" if self.date_requested == true               
      form_text += "<p align=\"center\"><label for=\"time\">Preferred Appointment Date</label><select id=\"time_requested\" name=\"submission[time_requested]\"><option value=\"Any\">Any</option><option value=\"ASAP\">ASAP</option><option value=\"8 AM\">8 AM</option><option value=\"9 AM\">9 AM</option><option value=\"10 AM\">10 AM</option><option value=\"Other\">Other</option></select></br>" if self.time_requested == true         
      form_text += "<p align=\"center\"><label for=\"other_information\">Questions or Comments</label><textarea name=\"submission[other_information]\"></textarea></br>" if self.other_information == true         
      form_text += "<p align=\"center\"><label for=\"time\">#{self.custom1_text}</label><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom1_value]\" size=\"20\" type=\"text\"/></br>" if self.custom1_text.present?
      form_text += "<p align=\"center\"><label for=\"time\">#{self.custom2_text}</label><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom2_value]\" size=\"20\" type=\"text\"/></br>" if self.custom2_text.present?
      form_text += "<p align=\"center\"><label for=\"time\">#{self.custom3_text}</label><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom3_value]\" size=\"20\" type=\"text\"/></br>" if self.custom3_text.present?
      form_text += "<p align=\"center\"><label for=\"time\">#{self.custom4_text}</label><input id=\"custom1_value\" maxlength=\"40\" name=\"submission[custom4_value]\" size=\"20\" type=\"text\"/></br>" if self.custom4_text.present?
      form_text += "<p align=\"center\"><input type=\"submit\" name=\"submit\" value=\"Submit Request\" onclick=\"return checkform()\"></form>"
      form_text
  end
  
  def get_form_snippet
    #<script type="text/javascript">var host = (("https:" == document.location.protocol) ? "https://secure." : "http://");document.write(unescape("%3Cscript src='" + host + "wufoo.com/scripts/embed/form.js' type='text/javascript'%3E%3C/script%3E"));</script>

    #<script type="text/javascript">
   # var z7x4a3 = new WufooForm();
    #z7x4a3.initialize({
    #'userName':'cityvoice', 
    #'formHash':'z7x4a3', 
    #'autoResize':true,
    #'height':'600'});
    #z7x4a3.display();
    #</script>
  end
  
  
  
  
end
