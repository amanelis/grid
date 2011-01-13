class AccountUser < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :account
  
  validate :unique_role?
  
  def unique?
    self.role.user.account_users.none? { |account_user| account_user.account == self.account }
  end
  
  
  private
  
  def unique_role?
    unless unique?
      errors.add_to_base("An account user role already exists for this user and account")
    end
  end
  
end
