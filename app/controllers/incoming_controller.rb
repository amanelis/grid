class IncomingController < ApplicationController

  # /incoming/:encoded_number/connect
  def connect
    encoded = CGI.unescape(params[:encoded_number])
    decoded = Base64.decode64(encoded)
    phone_number = PhoneNumber.find_by_inboundno(decoded)
    
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
  
  # /incoming/:encoded_number/connect?params.......
  def complete
    encoded = CGI.unescape(params[:encoded_number])
    decoded = Base64.decode64(encoded)
    phone_number = PhoneNumber.find_by_inboundno(decoded)
    
    call = phone_number.calls.build
    call.call_id          = params["CallSid"]
    call.call_status      = params["CallStatus"]
    call.caller_name      = params["CallerName"]
    call.caller_number    = params["Caller"].gsub("+", "")
    call.forwardno        = params["To"].gsub("+", "")
    call.inboundno        = params["From"].gsub("+", "")
    call.caller_city      = params["CallerCity"]
    call.caller_state     = params["CallerState"]
    call.caller_zipcode   = params["CallerZip"]
    call.caller_country   = params["CallerCountry"]
   
    #twilio_call = Call.get_twilio_call(params["CallSid"])
    #call.call_start = Time.parse(twilio_call["start_time"])
    #call.call_end = Time.parse(twilio_call["end_time"])
    #call.cost = twilio_call["price"]
    call.save!
    Call.fetch_twilio_recording(params["CallSid"])
    #Call.send_later(:fetch_twilio_recording, params["CallSid"]) if call.save!
    head 200
  end
  
  
end
