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

  REVIEW_STATUS_OPTIONS = [['Pending', PENDING], ['Unanswered', UNANSWERED], ['After Hours', AFTERHOURS], ['Spam', SPAM], ['Hangup', HANGUP], ['Wrong Number', WRONG_NUMBER], ['Other', OTHER], ['Lead', LEAD]].to_ordered_hash

  validates_inclusion_of :review_status, :in => REVIEW_STATUS_OPTIONS.values

  named_scope :answered, :conditions => {:call_status => ANSWERED_CALL}
  named_scope :canceled, :conditions => {:call_status => CANCELED_CALL}
  named_scope :voicemail, :conditions => {:call_status => VOICEMAIL_CALL}
  named_scope :other, :conditions => {:call_status => OTHER_CALL}

  # named_scope :lead, :conditions => ['call_status IN (?)', [ANSWERED_CALL, VOICEMAIL_CALL, OTHER_CALL]]

  named_scope :lead, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.review_status = ? OR activities.review_status = ?', PENDING, LEAD]
  }

  named_scope :unanswered, {
    :select => "calls.*",
    :joins => "INNER JOIN activities ON calls.id = activities.activity_type_id AND activities.activity_type_type = 'Call'", 
    :conditions => ['activities.review_status = ?', UNANSWERED]
  }

  named_scope :between, lambda { |start_date, end_date| {:conditions => ['call_start between ? AND ?', start_date.to_time.utc.at_beginning_of_day, end_date.to_time.utc.end_of_day]} }
  named_scope :snapshot, lambda { |start_datetime, duration| {:conditions => ['call_start between ? AND ?', start_datetime.utc, start_datetime.utc + duration.minutes]} }
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
            end
          end
        rescue Exception => ex
          exception = ex
          next
        end
      end
    rescue Exception => ex
      job_status.finish_with_errors(ex)
      raise
    end
    exception.present? ? job_status.finish_with_errors(exception) : job_status.finish_with_no_errors
    Account.cache_results_for_accounts
  end
  
  def self.fetch_call_recording(call_id)
    call = Call.find_by_call_id(call_id)
    call.fetch_call_recording
  end
  

  # INSTANCE BEHAVIOR
  
  def initialize_specifics(attributes={})
    self.review_status = PENDING
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
      self.review_status = HANGUP
    elsif self.call_status == CONGESTION_CALL
      self.review_status = HANGUP
    elsif self.call_status == NOANSWER_CALL
      self.review_status = UNANSWERED
    end
  end
  
end
