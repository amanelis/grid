
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
  
  def create_twilio_number()
    
  end
  
  #Returns an Array of Hashes for Available Phone Numbers within an area_code.
  def available_numbers(area_code = "210", country = "US")
    account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
    resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/AvailablePhoneNumbers/#{country}/Local?AreaCode=#{area_code}", 'GET')
    resp.error! unless resp.kind_of? Net::HTTPSuccess
    numbers = Array.new()
    if resp.code == '200'
      report = Nokogiri::XML(resp.body)
      rows = report.xpath("//AvailablePhoneNumber")
      numbers = Array.new()
      if rows.present?
        rows.each do |row|
          numbers.push({:FriendlyName => row.children[0].content, :PhoneNumber => row.children[1].content, :Lata => row.children[2].content, :RateCenter => row.children[3].content, :Latitude => row.children[4].content,
                        :Longitude => row.children[5].content, :Region => row.children[6].content, :PostalCode => row.children[7].content, :IsoCountry => row.children[8].content})
        end
      end
    end
    #puts "code: %s\nbody: %s" % [resp.code, resp.body]
    numbers.sort! {|a,b| a[:PhoneNumber].to_i <=> b[:PhoneNumber].to_i}
  end
  
  
end