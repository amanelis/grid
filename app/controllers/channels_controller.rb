class ChannelsController < ApplicationController
  inherit_resources
  load_resource :basic_channel, :through => :account
  load_and_authorize_resource :account
  belongs_to :account
  
  def index
  end
  
  def show
  end
end
