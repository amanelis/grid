class Utilities

  def self.merge_timeline_data(*hashes)
    hashes.flatten.inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| v1.merge!(v2) } }
  end

  def self.merge_and_sum_timeline_data(hashes, label)
    hashes.inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| {label => v1[label] + v2[label]} } }
  end

  def self.massage_timeline(timeline_hash, labels)
    dates = timeline_hash.keys.sort
    if dates.present?
      (dates.first..dates.last).each do |date|
        timeline_hash[date] = {} unless timeline_hash.has_key?(date)
        labels.each { |label| timeline_hash[date][label] = 0 unless timeline_hash[date].has_key?(label) }
      end
    end
    timeline_hash
  end
  
  def self.is_valid_email_address?(email_address)
    email_address =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/ ? true : false
  end
  
  def self.is_valid_phone_number?(phone_number)
    phone_number =~ /^(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?$/ ? true : false
  end
  
end