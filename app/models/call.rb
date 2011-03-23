require 'xmlrpc/client'
require 'xmlrpc/datetime'

class Call < ActiveRecord::Base
  include ActivityTypeMixin
  
  belongs_to :phone_number
  
  ANSWERED_CALL = "ANSWER"
  CANCELED_CALL = "CANCEL"
  VOICEMAIL_CALL = "VOICEMAIL"
  OTHER_CALL = "OTHER"
  NOANSWER_CALL = "NOANSWER"
  CONGESTION_CALL = "CONGESTION"
  BUSY_CALL = "BUSY"

  PENDING = 'pending'
  UNANSWERED = 'unanswered'
  AFTERHOURS = 'after hours'
  SPAM = 'spam'
  HANGUP = 'hangup'
  WRONG_NUMBER = 'wrong number'
  OTHER = 'other'
  LEAD = 'lead'
  FOLLOWUP = 'followup'

  ALL_REVIEW_STATUS_OPTIONS = [PENDING, UNANSWERED, AFTERHOURS, SPAM, HANGUP, WRONG_NUMBER, OTHER, LEAD, FOLLOWUP]

  UNIQUE_REVIEW_STATUS_OPTIONS = [['Pending', PENDING], ['Lead', LEAD], ['After Hours', AFTERHOURS], ['Spam', SPAM], ['Wrong Number', WRONG_NUMBER], ['Other', OTHER]].to_ordered_hash
  DUPLICATE_REVIEW_STATUS_OPTIONS = [['Pending', PENDING], ['Followup', FOLLOWUP], ['After Hours', AFTERHOURS], ['Spam', SPAM], ['Wrong Number', WRONG_NUMBER], ['Other', OTHER]].to_ordered_hash
  HANGUP_REVIEW_STATUS_OPTIONS = [['Hangup', HANGUP]].to_ordered_hash
  UNANSWERED_REVIEW_STATUS_OPTIONS = [['Unanswered', UNANSWERED]].to_ordered_hash
  
  DAYS_UNTIL_UNIQUE = 15.days

  validates_inclusion_of :review_status, :in => ALL_REVIEW_STATUS_OPTIONS

  named_scope :answered, :conditions => {:call_status => ANSWERED_CALL}
  named_scope :canceled, :conditions => {:call_status => CANCELED_CALL}
  named_scope :voicemail, :conditions => {:call_status => VOICEMAIL_CALL}
  named_scope :other, :conditions => {:call_status => OTHER_CALL}

  # named_scope :lead, :conditions => ['call_status IN (?)', [ANSWERED_CALL, VOICEMAIL_CALL, OTHER_CALL]]

  named_scope :lead, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.duplicate = FALSE AND (activities.review_status = ? OR activities.review_status = ?)', PENDING, LEAD]
  }

  named_scope :pending, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.review_status = ?', PENDING]
  }

  named_scope :unanswered, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.review_status = ?', UNANSWERED]
  }

  named_scope :reviewed, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.review_status <> ?', PENDING]
  }

  named_scope :unique, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.duplicate = FALSE']
  }

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['call_start between ? AND ?', start_date.to_time_in_current_zone.at_beginning_of_day.utc, end_date.to_time_in_current_zone.end_of_day.utc]} }
  named_scope :snapshot, lambda { |start_datetime, duration| {:conditions => ['call_start between ? AND ?', start_datetime.in_time_zone, start_datetime.in_time_zone + duration.minutes]} }
  named_scope :previous_hours, lambda { |*args| {:conditions => ['call_start > ?', (args.first || nil)], :order => 'call_start DESC'} }

  has_attached_file :recording,
                    :storage => :s3,
                    :s3_permissions => :private,
                    :s3_credentials => File.join(Rails.root, 'config', 's3.yml'),
                    :path => ':class/:id/:style.mp3'
  
  #validates_attachment_presence :recording
  #validates_attachment_content_type :recording, :content_type => [ 'application/mp3', 'application/x-mp3', 'audio/mpeg', 'audio/mp3' ]
 
  
  # CLASS BEHAVIOR

  def self.update_calls(start=(Time.now - 2.days), fend=(Time.now + 1.day))
    job_status = JobStatus.create(:name => "Call.update_calls")
    exception = nil
    orphan_campaign = Campaign.orphanage

    begin      
      server = XMLRPC::Client.new("api.voicestar.com", "/api/xmlrpc/1", 80)
      # or http://api.voicestar.com/
      server.user = 'reporting@cityvoice.com'
      server.password = 'C1tyv01c3'
      
      processed_calls = []
      
      results = server.call("acct.list")
      results.each do |result|
        begin
          searches = Struct.new(:start, :end)
          search_term = searches.new(start, fend)
          call_results = server.call("call.search", result["acct"], search_term)
          if call_results.present?
            call_results.each do |call_result|
              phone_number = PhoneNumber.find_by_cmpid_and_inboundno(call_result["cmpid"], call_result["inboundno"])
              if phone_number.blank?
                phone_number = orphan_campaign.phone_numbers.build
                phone_number.inboundno = call_result["inboundno"]
                phone_number.cmpid = call_result["cmpid"]
                phone_number.save!                
              end
              existing_call = Call.find_by_call_id(call_result["call_id"])
              if existing_call.blank?
                existing_call = Call.new
                existing_call.call_id = call_result["call_id"]
                existing_call.call_end = call_result["call_end"].to_time()
                existing_call.call_start = call_result["call_start"].to_time()
                existing_call.call_status = call_result["call_status"]
                existing_call.determine_default_review_status
                existing_call.caller_name = call_result["caller_name"]
                existing_call.caller_number = call_result["caller_number"]
                existing_call.forwardno = call_result["forwardno"]
                existing_call.inbound_ext = call_result["inbound_ext"]
                existing_call.inboundno = call_result["inboundno"]
                existing_call.recorded = call_result["recorded"]
                existing_call.phone_number_id = phone_number.id
              end
              existing_call.assigned_to = call_result["assigned_to"]
              existing_call.disposition = call_result["disposition"]
              existing_call.rating = call_result["rating"]
              existing_call.revenue = call_result["revenue"]
              Call.send_later(:fetch_call_recording, call_result["call_id"]) if existing_call.save!
              processed_calls << existing_call
            end
          end
        rescue Exception => ex
          exception = ex
          next
        end
      end
      processed_calls.each { |call| call.update_if_duplicate }
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
    GroupAccount.cache_results_for_group_accounts
  end
  
  def self.fetch_call_recording(call_id)
    call = Call.find_by_call_id(call_id)
    call.fetch_call_recording
  end
  
  def self.fetch_twilio_recording(callsid = 'CA0ae8ca05f42f14248d89a202cc9001be')
    call = Call.find_by_call_id(callsid)
    call.fetch_twilio_recording
  end
  
  def self.get_twilio_call(callsid = 'CA0ae8ca05f42f14248d89a202cc9001be')
    account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
    resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/Calls/#{callsid}.json", 'GET')
    return resp.error! unless resp.kind_of? Net::HTTPSuccess
    if resp.code == '200'
      return JSON.parse(resp.body)
    end
  end
  
  def self.total_revenue(calls)
    calls.to_a.sum { |call| call.revenue.to_f }
  end
  
  def self.average_ratings_per_disposition(calls)
    dispositions = calls.collect(&:disposition).uniq.inject({}) { |dispositions, disposition| dispositions[disposition] = [] ; dispositions }
    calls.each { |call| dispositions[call.disposition] << call.rating.to_f }
    dispositions.inject({}) { |averages, (key, value)| averages[key] = (value.empty? ? 0.0 : value.sum / value.size) ; averages }
  end


  # INITIALIZATION
  
  def initialize_thyself
    self.review_status = PENDING
  end
  

  # INSTANCE BEHAVIOR
  
  def get_twilio_call
    account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
    resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/Calls/#{self.call_id}.json", 'GET')
    return resp.error! unless resp.kind_of? Net::HTTPSuccess
    if resp.code == '200'
      return JSON.parse(resp.body)
    end
  end
  
  def update_if_duplicate
    self.update_attribute(:duplicate, true) if self.duplicate_calls_present?
  end
  
  def duplicate_calls_present?
    self.calls_from_same_number_over_past_days_until_unique.present?
  end

  def calls_from_same_number_over_past_days_until_unique
    return [] if self.caller_number.blank?
    Call.find(:all,
              :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'",
              :conditions => ['calls.id <> ? AND caller_number = ? AND phone_number_id = ? AND activities.review_status IN (?) AND (call_start between ? AND ?)', self.id, self.caller_number, self.phone_number_id, [PENDING, SPAM, WRONG_NUMBER, OTHER, LEAD, FOLLOWUP], self.call_start - DAYS_UNTIL_UNIQUE, self.call_start],
              :order => 'call_start DESC')
  end
  
  def duplicate_call_chain(chain = [])
    (calls = self.calls_from_same_number_over_past_days_until_unique).empty? ? chain << self : calls.pop.duplicate_call_chain(chain.concat(calls))
  end
  
  def fetch_call_recording(hard_update = false)
    return unless self.recorded?
    server = XMLRPC::Client.new("api.voicestar.com", "/api/xmlrpc/1", 80)
    server.user = 'reporting@cityvoice.com'
    server.password = 'C1tyv01c3'
    if !recording? || hard_update
      File.open("#{RAILS_ROOT}/tmp/#{call_id}.mp3", "a+") {|f| f.write(server.call("call.audio", call_id, 'mp3'))}
      self.recording = File.open("#{RAILS_ROOT}/tmp/#{call_id}.mp3")
      File.delete("#{RAILS_ROOT}/tmp/#{call_id}.mp3") if save!
    end
  end
  
  def fetch_twilio_recording(hard_update = false)
    ##Get the recording ID
    account = Twilio::RestAccount.new(ACCOUNT_SID, ACCOUNT_TOKEN)
    resp = account.request("/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/Calls/#{self.call_id}/Recordings.json", 'GET')
    return resp.error! unless resp.kind_of? Net::HTTPSuccess
      
    ##Get the recording
    if resp.code == '200'
      results = JSON.parse(resp.body)['recordings']
      File.open("#{RAILS_ROOT}/tmp/#{self.call_id}.mp3", "a+") {|f| f.write(HTTParty.get("https://api.twilio.com/#{API_VERSION}/Accounts/#{ACCOUNT_SID}/Recordings/#{results.last['sid']}.mp3"))}
      self.recording = File.open("#{RAILS_ROOT}/tmp/#{self.call_id}.mp3")
      File.delete("#{RAILS_ROOT}/tmp/#{self.call_id}.mp3") if save!
      self.recorded = true
      self.save
    end
  end
  
  def duration
    span = self.call_end - self.call_start
    min = (span / 60).floor
    secs = span.modulo(60).ceil
    min.to_s + (secs < 10 ? ":0" : ":") + secs.to_s
  end

  def call_start= the_start_time
    self[:call_start] = the_start_time
    self.timestamp = the_start_time
  end
  
  def determine_default_review_status
    return unless self.review_status == PENDING
    if self.call_status == CANCELED_CALL
      self.review_status = HANGUP 
    elsif self.call_status == BUSY_CALL
      self.review_status = UNANSWERED
    elsif self.call_status == CONGESTION_CALL
      self.review_status = UNANSWERED
    elsif self.call_status == NOANSWER_CALL
      self.review_status = UNANSWERED
    end
  end
  
  def review_status_options
    if self.review_status == HANGUP
      return HANGUP_REVIEW_STATUS_OPTIONS
    elsif self.review_status == UNANSWERED
      return UNANSWERED_REVIEW_STATUS_OPTIONS
    elsif self.duplicate?
      return DUPLICATE_REVIEW_STATUS_OPTIONS
    else
      return UNIQUE_REVIEW_STATUS_OPTIONS
    end
  end
  
  def campaign
    self.phone_number.campaign
  end

end
