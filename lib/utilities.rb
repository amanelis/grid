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

end