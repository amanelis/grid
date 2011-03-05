class BasicChannelsController < ApplicationController
  inherit_resources
  load_resource
  load_resource :account
  #load_and_authorize_resource :basic_channel, :through => :account
  belongs_to :account
  
  def new
    authorize! :manipulate_account, @account
    @basic_channel = BasicChannel.new(:account_id => params[:account_id])
  end
  
  def update
    update! do |success, failure|
      success.html {
        flash[:notice] = "Awesome! You just created updated your channel!"
        redirect_to account_path(@basic_channel.account) 
      }
      failure.html {
        flash[:error] = "Ooops, there was an error updating that Channel, you might want to try again."
        redirect_to edit_basic_channel_path(@basic_channel.account)
      }
    end
  end
  
  def create
    create! do |success, failure|
      success.html {
        flash[:notice] = "Awesome! You just created a new #{@basic_channel.name} channel!"
        redirect_to account_path(@basic_channel.account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error creating that Channel"
        render 'new'
      }
    end
  end
  
  def destroy
    destroy! do |success, failure|
      success.html {
        flash[:notice] = "Alright, that channel was deleted."
        redirect_to account_path(@basic_channel.account) 
      }
      failure.html {
        flash.now[:error] = "Ooops, there was an error deleting that Channel"
        render 'new'
      }
    end
  end
end
