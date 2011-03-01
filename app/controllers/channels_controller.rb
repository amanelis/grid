class ChannelsController < ApplicationController
  inherit_resources
  load_resource :basic_channel, :through => :account
  load_and_authorize_resource :account
  #load_and_authorize_resource :channel, :through => :account, :except => [:new, :create]
  belongs_to :account
  
  def show
  end
end
