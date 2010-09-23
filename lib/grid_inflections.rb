module GridArrayInflections
  def to_ordered_hash
   ordered_hash = ActiveSupport::OrderedHash.new
   self.each { |key, value| ordered_hash[key] = value }
   ordered_hash
  end
end

Array.send(:include, GridArrayInflections)
