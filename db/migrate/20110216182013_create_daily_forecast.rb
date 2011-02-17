class CreateDailyForecast < ActiveRecord::Migration
  def self.up
    create_table :daily_forecasts do |t|
      t.string :city
      t.string :zip_code, :null => false
      t.date :forecast_date, :null => false
      t.integer :low
      t.integer :high
      t.string :condition
      t.string :humidity
      t.string :icon
      t.string :wind_condition
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_forecasts
  end
end
