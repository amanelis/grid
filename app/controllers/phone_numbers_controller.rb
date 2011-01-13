
class PhoneNumbersController < ApplicationController
  
  
  def connect
    @r = Twilio::Response.new
    #@r.append(Twilio::Record.new())
    #@r.append(Twilio::Say.new("For quality purposes, your call will be recorded ", :voice => "woman", :loop => 1))
    @r.append(Twilio::Say.new("Chip, This is your computer. You're beard is looking mighty sexy! You and Lorenzo should fight or have a beard off. Winner take all.", :voice => "woman", :loop => 5))
    #@r.append(Twilio::Dial.new("2105389216"))
    puts @r.respond
    render :text => @r.respond
    
  end
  
  def collect
    #params.each do |param|
    #  puts param
    #end
    #params[:daterangepicker]
    
    #http://localhost:3000/phone_numbers/collect/688/?
    #AccountSid=AC7fedbe5d54f77671320418d20f843330&
    #ToZip=&
    #FromState=TX&
    #Called=%2B18665749611&
    #FromCountry=US&
    #CallerCountry=US&
    #CalledZip=&
    #Direction=inbound&
    #FromCity=SAN+ANTONIO&
    #CalledCountry=US&
    #Duration=1&
    #CallerState=TX&
    #CallSid=CA457c1285b3b7ac59620fa2c36883b2ea&
    #CalledState=&
    #From=%2B12105389224&
    #CallerZip=78206&
    #FromZip=78206&
    #CallStatus=completed&
    #ToCity=&
    #ToState=&
    #CallerName=CITY+VOICE&
    #To=%2B18665749611&
    #CallDuration=39&
    #ToCountry=US&
    #CallerCity=SAN+ANTONIO&
    #ApiVersion=2010-04-01&
    #Caller=%2B12105389224&
    #CalledCity=
  end
  
  
  
end