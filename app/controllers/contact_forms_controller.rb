class ContactFormsController < ApplicationController
  
  def get_html
    @form = ContactForm.find(params[:id])
  end
  
  
end