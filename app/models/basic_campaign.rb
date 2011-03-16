class BasicCampaign < ActiveRecord::Base
  include CampaignStyleMixin
  
  
  # INITIALIZATION
  
  def initialize_thyself
    self.campaign.initialize_thyself
  end
  

  # INSTANCE BEHAVIOR
  
  def number_of_visits_by_date
    self.campaign.number_of_visits_by_date
  end

  def number_of_leads_by_date
    self.campaign.number_of_leads_by_date
  end

  def combined_timeline_data
    {}
  end
  
  
  # PREDICATES
  
  def proper_channel?
    self.channel.blank? || self.channel.is_basic?
  end

end
