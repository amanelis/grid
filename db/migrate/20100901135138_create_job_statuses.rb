class CreateJobStatuses < ActiveRecord::Migration
  def self.up
    create_table :job_statuses do |t|
      t.string :name
      t.string :status
      t.text :error_message
      t.datetime :start_time
      t.datetime :end_time
      t.timestamps
    end
  end

  def self.down
    drop_table :job_statuses
  end
end
