
class PhoneNumbersController < ApplicationController
  
  
  def connect
    @phone_number = PhoneNumber.find(params[:id])
    if @phone_number.present?
      @r = Twilio::Response.new
      @r.append(Twilio::Say.new("For quality purposes, your call will be recorded ", :voice => "woman", :loop => 1))
      @r.append(Twilio::Dial.new(@phone_number.forward_to, :playBeep => false))
      @r.append(Twilio::Record.new())
      text_block = "Response: #{@r.respond}\ncampaign.name: #{@phone_number.campaign.name}\nname: #{@phone_number.name}\ninboundno: #{@phone_number.inboundno}\ncmpid: #{@phone_number.cmpid}\nforward_to: #{@phone_number.forward_to}\ntwilio_id: #{@phone_number.twilio_id}"
      render :text => text_block
    end
  end
  
  def collect
    begin
      @phone_number = PhoneNumber.find(params[:id])
      if @phone_number.blank?
        ##Try to create the number
      else
        call = @phone_number.calls.build
        call.forwardno = params[:Called]
        call.caller_name = params[:CallerName]
        call.inboundno = params[:From]
        call.call_id = params[:CallSid]
        call.call_status = params[:CallStatus]
        call.caller_city = params[:CallerCity]
        call.caller_state = params[:CallerState]
        call.caller_zip = params[:CallerZip]
        call.caller_country = params[:CallerCountry]
        twilio_call = call.get_twilio_call(params[:CallSid])
        call.call_start = twilio_call["start_time"]
        call.call_start = twilio_call["end_time"]
        call.price = twilio_call["price"]
        call.save!
        Call.fetch_twilio_call_recording(params[:CallSid])
        #Call.send_later(:fetch_twilio_call_recording, params[:CallSid]) if call.save!
      end
    rescue
      head 400
    end
    /
    processed_calls << existing_call
    /
  end
  
  
  
end