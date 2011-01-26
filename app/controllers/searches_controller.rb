class SearchesController < ApplicationController
  load_and_authorize_resource

  def index
    @search_term = params[:search].to_s.strip
    if @search_term.blank?
      @search_accounts = nil
      @search_campaigns = nil
    else
      @search_accounts = Account.name_like_all(@search_term).ascend_by_name
      @search_campaigns = Campaign.name_like_all(@search_term).ascend_by_name
    end
  end

end