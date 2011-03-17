class PhoneNumbersController < ApplicationController
  inherit_resources
  load_resource 
  load_resource :accounts 
  load_resource :channels
  load_resource :campaigns
  
  belongs_to :account
  belongs_to :channel
  belongs_to :campaign
  
  def index
  end
  
  def connect
    @phone_number = PhoneNumber.find(params[:id])
    forward_to = @phone_number.forward_to.blank? ? '2105289224' : @phone_number.forward_to
    @r = Twilio::Response.new
    record = @phone_number.record_calls == true ? "true" : "false"
    @r.append(Twilio::Say.new("For quality purposes, your call may be recorded ", :voice => "woman", :loop => "1"))
    @r.append(Twilio::Dial.new(forward_to, :record => record))
    #@r.append(Twilio::Redirect.new("2105389216"))
    #@r.append(Twilio::Dial.new(@phone_number.forward_to))
    #@r.append(Twilio::Record.new(:playBeep => "false")) if @phone_number.record_calls
    puts @r.respond
    #text_block = "Request: #{@r.respond}\nResponse: #{@r.respond}\ncampaign.name: #{@phone_number.campaign.name}\nname: #{@phone_number.name}\ninboundno: #{@phone_number.inboundno}\ncmpid: #{@phone_number.cmpid}\nforward_to: #{@phone_number.forward_to}\ntwilio_id: #{@phone_number.twilio_id}"
    render :text => @r.respond
  end
  
  def collect
    begin
      @phone_number = PhoneNumber.find(params[:id])
      if @phone_number.blank?
        ##Try to create the number
      else
        call = @phone_number.calls.build
        call.forwardno = params["Called"].gsub("+", "")
        call.caller_name = params["CallerName"]
        call.inboundno = params["From"].gsub("+", "")
        call.call_id = params["CallSid"]
        call.call_status = params["CallStatus"]
        call.caller_city = params["CallerCity"]
        call.caller_state = params["CallerState"]
        call.caller_zipcode = params["CallerZip"]
        call.caller_country = params["CallerCountry"]
        twilio_call = Call.get_twilio_call(params["CallSid"])
        call.call_start = Time.parse(twilio_call["start_time"])
        call.call_end = Time.parse(twilio_call["end_time"])
        call.cost = twilio_call["price"]
        call.save!
        Call.fetch_twilio_recording(params["CallSid"])
        #Call.send_later(:fetch_twilio_recording, params["CallSid"]) if call.save!
        head 200
      end
    rescue
      head 400
    end
  end
  
  
  
  
  
end