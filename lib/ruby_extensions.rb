# OBJECT

class Object
  def to_boolean
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(self)
  end
end


# ARRAY

class Array
  def to_ordered_hash
    ordered_hash = ActiveSupport::OrderedHash.new
    self.each { |key, value| ordered_hash[key] = value }
    ordered_hash
  end
end


# DATE

class Date
  def to_time_in_current_zone
    if ::Time.zone_default
      ::Time.zone.local(year, month, day)
    else
      to_time
    end
  end
end
