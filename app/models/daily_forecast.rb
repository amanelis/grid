class DailyForecast < ActiveRecord::Base
  
  def self.update_temperatures
    zips =  ((Campaign.all.collect {|camp| camp.zip_code || camp.account.postal_code }.uniq.compact.sort!).collect {|zip| zip[0..4] }.uniq).select {|zip| zip.length == 5 && Utilities.integer?(zip)}
    zips.each do |zip|
      begin
        response = HTTParty.get("http://www.google.com/ig/api?weather=#{zip}")
        forecast_date = response["xml_api_reply"]["weather"]["forecast_information"]["forecast_date"]["data"].to_date
        forecast = DailyForecast.first(:conditions => ['zip_code = ? AND forecast_date = ?', zip, forecast_date])  
        if forecast.blank?
          forecast = DailyForecast.new()
          forecast.zip_code = zip
          forecast.forecast_date = forecast_date
        end
        forecast.city = response["xml_api_reply"]["weather"]["forecast_information"]["city"]["data"]
        forecast.low = response["xml_api_reply"]["weather"]["forecast_information"]["low"]["data"].to_i if response["xml_api_reply"]["weather"]["forecast_information"]["low"].present?
        forecast.low = response["xml_api_reply"]["weather"]["forecast_conditions"].first["low"]["data"].to_i unless response["xml_api_reply"]["weather"]["forecast_information"]["low"].present?
        forecast.high = response["xml_api_reply"]["weather"]["forecast_information"]["high"]["data"].to_i if response["xml_api_reply"]["weather"]["forecast_information"]["high"].present?
        forecast.high = response["xml_api_reply"]["weather"]["forecast_conditions"].first["high"]["data"].to_i unless response["xml_api_reply"]["weather"]["forecast_information"]["high"].present?
        forecast.condition = response["xml_api_reply"]["weather"]["current_conditions"]["condition"]["data"]
        forecast.humidity = response["xml_api_reply"]["weather"]["current_conditions"]["humidity"]["data"]
        forecast.icon = "http://www.google.com#{response["xml_api_reply"]["weather"]["current_conditions"]["icon"]["data"]}"
        forecast.wind_condition = response["xml_api_reply"]["weather"]["current_conditions"]["wind_condition"]["data"]
        forecast.save!
        
        forecast_array = response["xml_api_reply"]["weather"]["forecast_conditions"][1..3].each do |next_forecast|
          forecast_date += 1.day
          forecast = DailyForecast.first(:conditions => ['zip_code = ? AND forecast_date = ?', zip, forecast_date]) 
          if forecast.blank?
            forecast = DailyForecast.new()
            forecast.zip_code = zip
            forecast.forecast_date = forecast_date
          end
          forecast.low = next_forecast["low"]["data"].to_i
          forecast.high = next_forecast["high"]["data"].to_i
          forecast.condition = next_forecast["condition"]["data"]
          forecast.icon = "http://www.google.com#{next_forecast["icon"]["data"]}"
          forecast.save! 
        end
        rescue
        end
      end
  end
  
end