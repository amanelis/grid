class Utilities

  def self.merge_timeline_data(*hashes)
    hashes.flatten.inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| v1.merge!(v2) } }
  end

  def self.merge_and_sum_timeline_data(hashes, label)
    hashes.inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| {label => v1[label] + v2[label]} } }
  end

end