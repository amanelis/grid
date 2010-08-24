class Admin::CampaignsController < ApplicationController
  before_filter :require_admin

  def show
    @campaign = Campaign.find(params[:id])
  end

end
