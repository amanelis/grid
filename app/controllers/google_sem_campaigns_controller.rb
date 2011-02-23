class GoogleSemCampaignsController < ApplicationController
  
  def show
    datepicker campaign_path(@google_sem_campaign)
    @google_sem_campaign = GoogleSemCampaign.find(params[:id]) if params[:id].present?
  end
  
end