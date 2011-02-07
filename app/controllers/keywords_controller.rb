class KeywordsController < ApplicationController
  load_and_authorize_resource
  
  def index
      @campaign = Campaign.find(params[:id])
      @keywords = @campaign.campaign_style.keywords 
  end
  
  def show
    @keyword  = Keyword.find(params[:id])
    @rankings = @keyword.keyword_rankings.sort { |a,b| b.created_at <=> a.created_at }
  end
  
end
