class Admin::SearchesController < ApplicationController
  before_filter :require_admin

  def index
    @search_term = params[:search]
    @search_accounts = Account.name_like_all(params[:search].to_s.split).ascend_by_name
    @search_campaigns = Campaign.name_like_all(params[:search].to_s.split).ascend_by_name
  end

end