
class PhoneNumbersController < ApplicationController
  
  
  def connect
    @r = Twilio::Response.new
    @r.append(Twilio::Record.new())
    @r.append(Twilio::Say.new("For quality purposes, your call will be recorded ", :voice => "woman", :loop => 1))
    @r.append(Twilio::Dial.new("2105389216"))
    puts @r.respond
    render :text => @r.respond
    
  end
  
  def collect
    
  end
  
  
  
end