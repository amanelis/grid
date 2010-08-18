class GoogleSemCampaign < ActiveRecord::Base
  belongs_to :sem_campaign
  has_many :adwords_campaign_summaries
  has_many :adwords_ad_groups


  # INSTANCE BEHAVIOR

  def spend_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    (self.cost_between(start_date, end_date) * 100.0) / (100.0 - self.rake)
  end

  def cost_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    self.adwords_campaign_summaries.between(start_date, end_date).sum(:cost) / 1000000.0
  end

  def rake
    (rake = self.sem_campaign.rake).present? ? rake : 0.0
  end

  def cost_per_lead_between(start_date = Date.today - 1.day, end_date = Date.today - 1.day)
    total_leads = self.campaign.number_of_total_leads_between(start_date, end_date)
    total_leads > 0 ? self.spend_between(start_date, end_date) / total_leads : 0.0
  end


end
