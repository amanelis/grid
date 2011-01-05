class AccountUser < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :account
  
end
