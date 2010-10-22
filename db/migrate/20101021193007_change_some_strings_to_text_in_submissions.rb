class ChangeSomeStringsToTextInSubmissions < ActiveRecord::Migration
  def self.up
    change_column :submissions, :work_description, :text
    change_column :submissions, :other_information, :text
  end

  def self.down
    change_column :submissions, :work_description, :string
    change_column :submissions, :other_information, :string
  end
end
