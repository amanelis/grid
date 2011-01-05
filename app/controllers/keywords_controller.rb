class KeywordsController < ApplicationController
  before_filter :require_admin
  
  def index
      @campaign = Campaign.find(params[:id])
      #@keywords = Array.new
      @keywords = @campaign.campaign_style.keywords 
  end
  
  def show
    @keyword = Keyword.find(params[:id])
    @rankings = @keyword.keyword_rankings.sort { |a,b| b.created_at <=> a.created_at }
    
  end
  
end
