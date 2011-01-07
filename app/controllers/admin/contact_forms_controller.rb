class Admin::ContactFormsController < ApplicationController
  before_filter :require_admin

  def new
    @campaign = Campaign.find(params[:id])
    @contact_form = @campaign.contact_forms.build

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @contact_form }
      end
  end

end