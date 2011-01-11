class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :roles
  
  
  # INSTANCE BEHAVIOR

  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    UserMailer.deliver_password_reset_instructions(self)  
  end
  
  def acquainted_with_group_account?(group_account)
    return true if self.admin?
    self.roles.account_manager.any? { |role| role.role_type.group_account == group_account }
  end

  def acquainted_with_account?(account)
    return true if self.admin?
    return true if self.roles.account_manager.any? { |role| role.role_type.group_account == account.group_account }
    self.roles.account_user.any? { |role| role.role_type.account == account }
  end

  def acquainted_with_campaign?(campaign)
    return true if self.admin?
    return true if self.roles.account_manager.any? { |role| role.role_type.group_account == campaign.account.group_account }
    self.roles.account_user.any? { |role| role.role_type.account == campaign.account }
  end
  
  def acquainted_group_accounts
    return GroupAccounts.all if self.admin?
    self.roles.account_manager.collect { |role| role.role_type.group_account }
  end
  
  def acquainted_accounts
    return Accounts.all if self.admin?
    (self.roles.account_manager.collect { |role| role.role_type.group_account.accounts } << self.roles.account_user.collect { |role| role.role_type.account }).flatten.compact.uniq
  end
  
end
