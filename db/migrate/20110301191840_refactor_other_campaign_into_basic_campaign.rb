class RefactorOtherCampaignIntoBasicCampaign < ActiveRecord::Migration
  def self.up
    rename_table(:other_campaigns, :basic_campaigns)
    Campaign.all.each { |campaign| campaign.update_attribute(:campaign_style_type, 'BasicCampaign') if campaign.campaign_style_type == 'OtherCampaign' }
  end

  def self.down
    rename_table(:basic_campaigns, :other_campaigns)
    Campaign.all.each { |campaign| campaign.update_attribute(:campaign_style_type, 'OtherCampaign') if campaign.campaign_style_type == 'BasicCampaign' }
  end
end
