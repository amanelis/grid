class AddUserAgentToSubmission < ActiveRecord::Migration
  def self.up
    add_column :submissions, :user_agent, :string
  end

  def self.down
    remove_column :submissions, :user_agent
  end
end
