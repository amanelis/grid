class CreateAdwordsCampaignSummaries < ActiveRecord::Migration
  def self.up
    create_table :adwords_campaign_summaries do |t|
      t.references :google_sem_campaign, :null => false
      t.integer :imps
      t.float :pos
      t.float :cpc
      t.float :cpm
      t.float :ctr
      t.string :status
      t.integer :clicks
      t.integer :conv
      t.float :cost
      t.float :budget
      t.integer :invalid_clicks
      t.integer :total_interactions
      t.float :exact_match_imp_share
      t.float :imp_share
      t.float :lost_imp_share_budget
      t.float :lost_imp_share_rank
      t.date :report_date
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_campaign_summaries
  end
end
