class AddReviewStatusToCallsAndSubmissions < ActiveRecord::Migration
  def self.up
    add_column :calls, :review_status, :string
    Call.reset_column_information
    Call.all.each { |call| call.update_attribute(:review_status, Submission::PENDING) }
    add_column :submissions, :review_status, :string
    Submission.reset_column_information
    Submission.all.each { |submission| submission.update_attribute(:review_status, Submission::PENDING) }
  end

  def self.down
    remove_column :calls, :review_status
    remove_column :submissions, :review_status
  end
end
