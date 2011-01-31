module TwilioInflections
  class Twilio::Dial
    attributes :record
  end
end

Twilio::Dial.send(:include, TwilioInflections)
