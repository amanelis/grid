class AddPaperclipFieldsToCall < ActiveRecord::Migration
  def self.up
    add_column :calls, :recording_file_name, :string
    add_column :calls, :recording_content_type, :string
    add_column :calls, :recording_file_size, :integer
    add_column :calls, :recording_updated_at, :datetime
  end

  def self.down
    remove_column :calls, :recording_file_name
    remove_column :calls, :recording_content_type
    remove_column :calls, :recording_file_size
    remove_column :calls, :recording_updated_at
  end

end

