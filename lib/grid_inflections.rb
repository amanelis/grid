module GridArrayInflections
  def to_ordered_hash
   ordered_hash = ActiveSupport::OrderedHash.new
   self.each { |key, value| ordered_hash[key] = value }
   ordered_hash
  end
end

Array.send(:include, GridArrayInflections)


module GridDateInflections
  def to_time_in_current_zone
    if ::Time.zone_default
      ::Time.zone.local(year, month, day)
    else
      to_time
    end
  end
end

Date.send(:include, GridDateInflections)

module GridTwilioInflections
  class Twilio::Dial
    attributes :record
  end
end

Twilio::Dial.send(:include, GridTwilioInflections)
