class IncomingController < ApplicationController

  # /incoming/:encoded_number/connect
  def connect
    encoded = CGI.unescape(params[:encoded_number])
    decoded = Base64.decode64(encoded)
    phone_number = PhoneNumber.find_by_inboundno(decoded)
    
    call = phone_number.calls.build
    call.call_id    = params["CallSid"]
    call.call_start = Time.now
    call.timestamp  = Time.now
    call.save!
    
    unless phone_number.nil?
      record = phone_number.record_calls == true ? "true" : "false"
      response = Twilio::Response.new
      response.append(Twilio::Say.new("For quality purposes, your call may be recorded ", :voice => "woman", :loop => "1"))
      response.append(Twilio::Dial.new(phone_number.forward_to, :record => record))
      render :text => response.respond
    else
      render :text => "The URL you passed was invalid."
    end
  end
  
  # /incoming/:encoded_number/complete
  def complete
    encoded = CGI.unescape(params[:encoded_number])
    decoded = Base64.decode64(encoded)
    phone_number  = PhoneNumber.find_by_inboundno(decoded)
    incoming_call = Call.find_by_call_id(params["CallSid"])
    
    incoming_call.update_attributes(:call_status => params["CallStatus"], 
                                    :caller_name => params["CallerName"], 
                                    :caller_number => params["Caller"].gsub("+", ""), 
                                    :forwardno => params["To"].gsub("+", ""),
                                    :inboundno => params["From"].gsub("+", ""),
                                    :caller_city => params["CallerCity"],
                                    :caller_state => params["CallerState"],
                                    :caller_zipcode => params["CallerZip"],
                                    :caller_country => params["CallerCountry"],
                                    :call_end => incoming_call.call_start + params["Duration"].to_i.minute)
   
    Call.fetch_twilio_recording(params["CallSid"])
    Call.send_later(:fetch_twilio_recording, params["CallSid"]) 
    head 200
  end
  
  
end
