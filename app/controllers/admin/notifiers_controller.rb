class Admin::NotifiersController < ApplicationController
  before_filter :require_admin
  
  def weekly_report
    if params[:id].blank?
      render :text => "Error on report"
    else
      @account_report_data = Account.find(params[:id])
      @account_report_data.previous_days_report_data
    end
  end
end