class CreateAdwordsAdSummaries < ActiveRecord::Migration
  def self.up
    create_table :adwords_ad_summaries do |t|
      t.references :adwords_ad, :null => false
      t.integer :conv
      t.float :cost
      t.float :budget
      t.integer :default_conv
      t.float :default_conv_value
      t.float :first_page_cpc
      t.integer :imps
      t.integer :leads
      t.float :lead_value
      t.float :max_content_cpc
      t.float :max_cpc
      t.float :max_cpm
      t.integer :page_views
      t.float :page_view_value
      t.float :ag_max_cpa
      t.float :avg_conv_value
      t.float :pos
      t.float :avg_percent_played
      t.float :bottom_position
      t.float :cpc
      t.float :cpm
      t.float :ctr
      t.integer :quality_score
      t.integer :purchases
      t.float :purchase_value
      t.integer :sign_ups
      t.float :sign_up_value
      t.integer :top_position
      t.float :conv_value
      t.integer :transactions
      t.float :conv_vpc
      t.float :value_cost_ratio
      t.integer :video_playbacks
      t.integer :video_playbacks_through_100_percent
      t.integer :video_playbacks_through_50_percent
      t.integer :video_playbacks_through_25_percent
      t.integer :video_playbacks_through_75_percent
      t.integer :video_skips
      t.float :keyword_min_cpc
      t.date :summary_date
      t.float :cpt
      t.float :cost_per_video_playback
      t.float :conv_rate
      t.float :cost_per_conv
      t.integer :clicks
      t.timestamps
    end
  end

  def self.down
    drop_table :adwords_ad_summaries
  end
end
