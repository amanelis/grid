class BasicChannelsController < ApplicationController
  inherit_resources
  load_and_authorize_resource :basic_channel, :through => :account
  belongs_to :account
  
  def index
  end
  
  def show
  end
  
  def new
    @basic_channel = BasicChannel.new(:account_id => params[:account_id])
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
