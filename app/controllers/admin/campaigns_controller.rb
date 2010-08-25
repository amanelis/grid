class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
    @timeline = @campaign.combined_timeline_data
    @sorted_dates = @timeline.keys.sort
  end

end