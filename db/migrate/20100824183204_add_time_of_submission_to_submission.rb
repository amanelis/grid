class AddTimeOfSubmissionToSubmission < ActiveRecord::Migration
  def self.up
    add_column :submissions, :time_of_submission, :datetime
  end

  def self.down
    remove_column :submissions, :time_of_submission
  end
end
