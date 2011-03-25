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
    return true unless self.campaign.account.active?
    return true unless self.campaign.active?
    self.active? ? false : true
  end
  
  def get_form_text
      #form_text += "<tr><td><textarea id=\"home_address\" name=\"submission[home_address]\" onFocus=\"javascript:this.value=\'\'\" style=\"width:100%;\" >Address:</textarea></td></tr>" if self.need_address == true
      #form_text += "<tr><td><select id=\"work_category\" name=\"submission[work_category]\"><option value=\"\">Work Request</option><option value=\"Category 1\">Category 1</option><option value=\"Category 2\">Category 2</option><option value=\"Category 3\">Category 3</option></select></td></tr>" if self.work_category == true            
      #form_text += "<tr><td><input id=\"date_requested\" name=\"submission[date_requested]\" type=\"text\" value=\"Preferred Appointment Date:\"  style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.date_requested == true               
      #form_text += "<tr><td><select id=\"time_requested\" name=\"submission[time_requested]\"><option value=\"\">Preferred Appointment Time</option><option value=\"Any\">Any</option><option value=\"ASAP\">ASAP</option><option value=\"8 AM\">8 AM</option><option value=\"9 AM\">9 AM</option><option value=\"10 AM\">10 AM</option><option value=\"Other\">Other</option></select></td></tr>" if self.time_requested == true         
      #form_text += "<tr><td><textarea name=\"submission[other_information]\" onFocus=\"javascript:this.value=\'\'\" style=\"width:100%;\" >Questions or Comments:</textarea></td></tr>" if self.other_information == true         
      #form_text += "<tr><td><input id=\"custom1_value\" name=\"submission[custom1_value]\" type=\"text\" value=\"#{self.custom1_text}:\"  style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.custom1_text.present?
      #form_text += "<tr><td><input id=\"custom2_value\" name=\"submission[custom2_value]\" type=\"text\" value=\"#{self.custom2_text}:\"  style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.custom2_text.present?
      #form_text += "<tr><td><input id=\"custom3_value\" name=\"submission[custom3_value]\" type=\"text\" value=\"#{self.custom3_text}:\"  style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.custom3_text.present?
      #form_text += "<tr><td><input id=\"custom4_value\" name=\"submission[custom4_value]\" type=\"text\" value=\"#{self.custom4_text}:\"  style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.custom4_text.present?
      
      #form_text = "<form action=\"http://#{APP_CONFIG[:host]}/submission\" method=\"POST\" name=\"Form1\" onSubmit=\"return checkform()\"><input type=hidden id=\"contact_form_id\" name=\"submission[contact_form_id]\" value=\"#{self.id}\"> <input type=hidden name=\"submission[retURL]\" value=\"#{self.return_url}\"><table width=\"100%\" border=\"0\" cellspacing=\"2\" cellpadding=\"2\">"
      #form_text += "<form action=\"http://#{APP_CONFIG[:host]}/api/forms/submit\" method=\"POST\" name=\"Form1\" onSubmit=\"return checkform()\"><input type=hidden id=\"contact_form_id\" name=\"submission[contact_form_id]\" value=\"#{self.id}\"> <input type=hidden name=\"submission[retURL]\" value=\"#{self.return_url}\"><table width=\"100%\" border=\"0\" cellspacing=\"2\" cellpadding=\"2\">"
      #form_text += "<tr><td><input id=\"first_name\" name=\"submission[name]\" type=\"text\" value=\"Name:\" style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.need_name 
      #form_text += "<tr><td><input id=\"phone_number\" name=\"submission[phone_number]\" type=\"text\"  value=\"Phone #:\" style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.need_phone 
      #form_text += "<tr><td><input id=\"from_email\" name=\"submission[from_email]\" type=\"text\" value=\"Email:\" style=\"width:100%;\" onFocus=\"javascript:this.value=\'\'\" /></td></tr>" if self.need_email 
      #form_text += "<tr><td><textarea id=\"work_description\" name=\"submission[work_description]\" onFocus=\"javascript:this.value=\'\'\" style=\"width:100%;\" >Description of work:</textarea></td></tr>" if self.work_description 
      #form_text += "<tr><td align=\"right\"><input type=\"submit\" name=\"submit\" value=\"Submit Request\" onclick=\"return checkform()\"></td></tr></table></form>"
      #form_text
      
      form_text = '<style>'
    	form_text += 'label       { font-weight: bold; }'
    	form_text += 'fieldset    { padding:0 1.4em 1.4em 1.4em; margin: 0 0 1.5em 0; border: 1px solid #ccc; }'
    	form_text += 'legend      { font-weight: bold; font-size:1.2em; margin-top:-0.2em; margin-bottom:1em; }'
    	form_text += 'fieldset, #IE8#HACK { padding-top:1.4em; }'
    	form_text += 'legend, #IE8#HACK { margin-top:0; margin-bottom:0; }'
    	form_text += 'input[type=text], input[type=password],'
    	form_text += 'input.text, input.title,'
    	form_text += 'textarea {'
    	form_text += '  background-color:#fff;'
    	form_text += '  border:1px solid #bbb;'
    	form_text += '}'
    	form_text += 'input[type=text]:focus, input[type=password]:focus,'
    	form_text += 'input.text:focus, input.title:focus,'
    	form_text += 'textarea:focus {'
    	form_text += '  border-color:#666;'
    	form_text += '}'
    	form_text += 'select { background-color:#fff; border-width:1px; border-style:solid; }'
    	form_text += 'input[type=text], input[type=password],'
    	form_text += 'input.text, input.title,'
    	form_text += 'textarea, select {'
    	form_text += '  margin:0.5em 0;'
    	form_text += '}'
    	form_text += 'input.text,'
    	form_text += 'input.title   { width: 300px; padding:5px; }'
    	form_text += 'input.title   { font-size:1.5em; }'
    	form_text += 'textarea      { width: 390px; height: 250px; padding:5px; }'
    	form_text += 'form.inline { line-height:3; }'
    	form_text += 'form.inline p { margin-bottom:0; }'
    	form_text += '.error,'
    	form_text += '.alert,'
    	form_text += '.notice,'
    	form_text += '.success,' 
    	form_text += '.info 			{ padding: 0.8em; margin-bottom: 1em; border: 2px solid #ddd; }'
    	form_text += '.error, .alert { background: #fbe3e4; color: #8a1f11; border-color: #fbc2c4; }'
    	form_text += '.notice     { background: #fff6bf; color: #514721; border-color: #ffd324; }'
    	form_text += '.success    { background: #e6efc2; color: #264409; border-color: #c6d880; }'
    	form_text += '.info 			{ background: #d5edf8; color: #205791; border-color: #92cae4; }'
    	form_text += '.error a, .alert a { color: #8a1f11; }'
    	form_text += '.notice a   { color: #514721; }'
    	form_text += '.success a  { color: #264409; }'
    	form_text += '.info a			{ color: #205791; }'
    	form_text += 'textarea, input{'
    	form_text += '  width:100%;'
    	form_text += '}'
    	form_text += 'form{'
    	form_text += '  padding:24px;'
    	form_text += '}'
    	form_text += '</style>'
    	
    	form_text += "<form action=\"http://#{APP_CONFIG[:host]}/api/forms/submit\" method=\"POST\" name=\"Form1\" onSubmit=\"return checkform()\">"
      form_text += "<input type=hidden id=\"contact_form_id\" name=\"submission[contact_form_id]\" value=\"#{self.id}\">"
      form_text += "<input type=hidden name=\"submission[retURL]\" value=\"#{self.return_url}\">"
      form_text += "<label>Name*</label><br>"
      form_text += "<input id=\"first_name\" name=\"submission[name]\" type=\"text\"><br>"
      form_text += "<label>Phone Number*</label><br>"
      form_text += "<input id=\"phone_number\" name=\"submission[phone_number]\" type=\"text\"><br>"
      form_text += "<label>Email*</label><br>"
      form_text += "<input id=\"from_email\" name=\"submission[from_email]\" type=\"text\"><br>"
      form_text += "<label>Work Description*</label><br>"
      form_text += "<textarea id=\"work_description\" name=\"submission[work_description]\"></textarea><br>"
      form_text += "<input type=\"submit\" name=\"submit\" value=\"Submit Request\" onclick=\"return checkform()\">"
      form_text += "</form>"
      form_text
  end
  
  def generate_js_snippet
    form_text =   "<script type=\"text/javascript\">"
    form_text +=  "var host = document.write(unescape(\"%3Cscript src='http://#{APP_CONFIG[:host]}/javascripts/form.js' type='text/javascript'%3E%3C/script%3E\"));"
    form_text +=  "</script>"
    form_text +=  "<script type=\"text/javascript\">"
    form_text +=  "var myform = new GridForm();"
    form_text +=  "myform.initialize({"
    form_text +=  "form_id: #{self.id}"
    form_text +=  "});"
    form_text +=  "myform.display();"
    form_text +=  "</script>"
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
  
  def get_iframe_code
    #return "<iframe src=\"http://#{APP_CONFIG[:host]}/contact_forms/#{self.id}/get_html\" width=\"300\" height=\"375\"></iframe>"
    return "<iframe src=\"http://#{APP_CONFIG[:host]}/api/forms/#{self.id}/get_html\" width=\"300\" height=\"375\"></iframe>"
  end
  
  def time_zone
    self.campaign.time_zone
  end

end
