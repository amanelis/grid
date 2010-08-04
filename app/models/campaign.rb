class Campaign < ActiveRecord::Base
  belongs_to :account
  belongs_to :campaign_style, :polymorphic => true
  has_many :phone_numbers
  has_many :contact_forms
  has_many :websites
end
