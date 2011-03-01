class BasicCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  
  belongs_to :basic_channel

  
  def number_of_visits_by_date
    self.campaign.number_of_visits_by_date
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

  def combined_timeline_data
    {}
  end

end
