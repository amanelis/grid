
class PhoneNumbersController < ApplicationController
  # Twilio REST API version
  API_VERSION = '2010-04-01'

  # Twilio AccountSid and AuthToken
  ACCOUNT_SID = 'AC7fedbe5d54f77671320418d20f843330'
  ACCOUNT_TOKEN = 'a7a72b0eb3c8a41064c4fc741674a903'
  
  
  def connect
    @r = Twilio::Response.new
    @r.append(Twilio::Say.new("For quality purposes, your call will be recorded ", :voice => "woman", :loop => 1))
    @r.append(Twilio::Dial.new("2105389224"))
    @r.append(Twilio::Record.new())

    puts @r.respond
    render :text => @r.respond
    
  end
  
  def collect
    
  end
  
  def create_twilio_number
    
  end
  
  
end