class ChannelsController < ApplicationController
  inherit_resources
  load_resource
  load_resource :account
  belongs_to :account
  
  def new
    render :layout => false
    authorize! :manipulate_account, @account
  end
  
  def show
    authorize! :manipulate_account, @account
  end
  
  def edit
    render :layout => false
    authorize! :manipulate_account, @account
  end
  
  def update
    update! do |success, failure|
      success.html {
        flash[:notice] = "Awesome! You just created updated your channel!"
        redirect_to account_path(@channel.account) 
      }
      failure.html {
        flash[:error] = "Ooops, there was an error updating that Channel, you might want to try again."
        redirect_to edit_channel_path(@channel.account)
      }
    end
  end
  
  def create
    @channel = Channel.new
    @channel.account = @account
    @channel.name = params[:channel][:name]
    if params[:channel][:channel_type].include?("seo")
      @channel.set_type_seo
    elsif params[:channel][:channel_type].include?("sem")
      @channel.set_type_sem
    elsif params[:channel][:channel_type].include?("basic") || params[:channel][:channel_type].blank?
      @channel.set_type_basic
    end
    @channel.save
    flash[:notice] = "Yay channel created!"
    redirect_to account_path(@account)
  end
  
  def destroy
    destroy! do |success, failure|
      success.html {
        flash[:notice] = "Alright, that channel was deleted."
        redirect_to account_path(@channel.account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error deleting that Channel"
        render 'new'
      }
    end
  end
end
