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


# STRING

class String
  def truncate(length, options = {})
    text = self.dup
    options[:omission] ||= "..."

    length_with_room_for_omission = length - options[:omission].mb_chars.length
    chars = text.mb_chars
    stop = options[:separator] ?
      (chars.rindex(options[:separator].mb_chars, length_with_room_for_omission) || length_with_room_for_omission) : length_with_room_for_omission

    (chars.length > length ? chars[0...stop] + options[:omission] : text).to_s
  end
end
