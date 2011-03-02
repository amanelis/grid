class BasicChannelsController < ApplicationController
  inherit_resources
  #load_and_authorize_resource :basic_channel, :through => :account
  #load_resource :basic_channel, :through => :account
  #load_and_authorize_resource :account
  belongs_to :account
  
  def index
  end
  
  def show
  end
  
  def new
    @basic_channel = BasicChannel.new(:account_id => params[:account_id])
  end
  
  def create
    create!
  end
end
