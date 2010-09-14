class OtherCampaign < ActiveRecord::Base
  include CampaignStyleMixin

  
  def number_of_visits_by_date
    self.campaign.number_of_visits_by_date
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

end
