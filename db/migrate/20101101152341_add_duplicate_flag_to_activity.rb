class AddDuplicateFlagToActivity < ActiveRecord::Migration
  def self.up
    add_column :activities, :duplicate, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :activities, :duplicate
  end
end
