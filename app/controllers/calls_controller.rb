class CallsController < ApplicationController
  # Twilio REST API version
  API_VERSION = '2010-04-01'

  # Twilio AccountSid and AuthToken
  ACCOUNT_SID = 'AC7fedbe5d54f77671320418d20f843330'
  ACCOUNT_TOKEN = 'a7a72b0eb3c8a41064c4fc741674a903'
  def index
    @r = Twilio::Response.new
    @r.append(Twilio::Say.new("For quality purposes, your call will be recorded ", :voice => "woman"))
    @r.append(Twilio::Record.new())
    @r.append(Twilio::Dial.new("2105389224", :timeLimit => "45"))

    puts @r.respond
  end
  
end