class ContactForm < ActiveRecord::Base
  belongs_to :campaign
  has_many :submissions  
end
