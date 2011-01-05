class AccountManager < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :group_account
  has_many :accounts
  
end
