class IncomingController < ApplicationController
  
  def show
    @phone_number = PhoneNumber.find(params[:id])
  end
end
