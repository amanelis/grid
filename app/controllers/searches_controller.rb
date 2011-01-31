class SearchesController < ApplicationController
  load_and_authorize_resource :account, :campaign
  
  def index
    @accounts     = current_user.acquainted_accounts
    @campaigns    = current_user.acquainted_campaigns
    @search_term  = params[:search].to_s.strip
    unless @search_term.blank?
      @search_accounts  = Account.name_like_all(@search_term).ascend_by_name.select  {|result| @accounts.include?(result)}
      @search_campaigns = Campaign.name_like_all(@search_term).ascend_by_name.select {|result| @campaigns.include?(result)}
    end
  end

end