class AccountManager < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :group_account
  has_many :accounts

  validate :unique_role?
  
  def unique?
    self.role.user.account_managers.none? { |account_manager| account_manager.group_account == self.group_account }
  end
  
  
  private
  
  def unique_role?
    unless unique?
      errors.add_to_base("An account manager role already exists for this user and group account")
    end
  end
 
end
