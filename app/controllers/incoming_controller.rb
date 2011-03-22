class IncomingController < ApplicationController
  
  def show
    number = CGI.unescape(params[:id])
    decoded = Base64.decode64(number)
    render :text => decoded
  end
end
