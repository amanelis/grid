class AddMobileFlagToSemCampaign < ActiveRecord::Migration
  def self.up
    add_column :sem_campaigns, :mobile, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :sem_campaigns, :mobile
  end
end
