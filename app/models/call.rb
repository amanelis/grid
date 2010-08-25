require 'xmlrpc/client'
require 'xmlrpc/datetime'

class Call < ActiveRecord::Base
  belongs_to :phone_number

  ANSWERED_CALL = "ANSWER"
  CANCELED_CALL = "CANCEL"
  VOICEMAIL_CALL = "VOICEMAIL"
  OTHER_CALL = "OTHER"

  named_scope :answered, :conditions => {:call_status => ANSWERED_CALL}
  named_scope :canceled, :conditions => {:call_status => CANCELED_CALL}
  named_scope :voicemail, :conditions => {:call_status => VOICEMAIL_CALL}
  named_scope :other, :conditions => {:call_status => OTHER_CALL}
  named_scope :lead, :conditions => ['call_status IN (?)', [ANSWERED_CALL, VOICEMAIL_CALL, OTHER_CALL]]

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['call_start between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }


  # CLASS BEHAVIOR

  def self.update_calls(start=(Time.now - 2.days), fend=(Time.now + 1.day))
    server = XMLRPC::Client.new("api.voicestar.com", "/api/xmlrpc/1", 80)
    # or http://api.voicestar.com/
    server.user = 'reporting@cityvoice.com'
    server.password = 'C1tyv01c3'
    begin
      results = server.call("acct.list")
    rescue
      #TODO: need to do something with this exception
    end
    results.each do |result|
      begin
        searches = Struct.new(:start, :end)
        search_term = searches.new(start, fend)
        call_results = server.call("call.search", result["acct"], search_term)
        if call_results.present?
          call_results.each do |call_result|
            phone_number = PhoneNumber.find_by_cmpid(call_result["cmpid"])
            if phone_number.present?
              Call.find_or_create_by_call_id(:call_id => call_result["call_id"],
                                             :assigned_to => call_result["assigned_to"],
                                             :call_end => call_result["call_end"].to_time(),
                                             :call_start => call_result["call_start"].to_time(),
                                             :call_status => call_result["call_status"],
                                             :caller_name => call_result["caller_name"],
                                             :caller_number => call_result["caller_number"],
                                             :disposition => call_result["disposition"],
                                             :forwardno => call_result["forwardno"],
                                             :inbound_ext => call_result["inbound_ext"],
                                             :inboundno => call_result["inboundno"],
                                             :rating => call_result["rating"],
                                             :revenue => call_result["revenue"],
                                             :recorded => call_result["recorded"],
                                             :phone_number_id => phone_number.id)
            else
              puts "Erroring finding Phone Number Campaign ID: " + call_result["cmpid"]
            end
          end
        end
      rescue
        next
        puts 'Error'
        #TODO: need to do something with this exception
      end
    end
  end

end
