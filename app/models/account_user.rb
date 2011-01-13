class AccountUser < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :account
  
  validate :unique_role?
  
  def unique?
    self.role.user.roles.account_user.to_a.none? { |role| role.role_type.account == self.account }
  end
  
  
  private
  
  def unique_role?
    unless unique?
      errors.add_to_base("An account user role already exists for this user and account")
    end
  end
  
end
