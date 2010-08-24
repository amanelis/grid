class Utilities

  def self.merge_timeline_data(*hashes)
    hashes.inject({}) { |data, a_hash| data.merge!(a_hash) { |key, v1, v2| v1.merge(v2) } }
  end

end