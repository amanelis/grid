class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.references :activity_type, :polymorphic => true, :null => false
      t.string :review_status
      t.datetime :timestamp
    end
    Activity.reset_column_information
    Call.all.each do |call|
      call.activity = Activity.new
      call.review_status = Call::PENDING
      call.timestamp = call.call_start
      call.activity.save
    end
    Submission.all.each do |submission|
      submission.activity = Activity.new
      submission.review_status = Submission::PENDING
      submission.timestamp = submission.time_of_submission
      submission.activity.save
    end
  end

  def self.down
    drop_table :activities
  end
end
