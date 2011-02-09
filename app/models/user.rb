class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :roles
  
  has_many :group_users, :through => :roles, :source => :role_type, :source_type => 'GroupUser'
  has_many :account_managers, :through => :roles, :source => :role_type, :source_type => 'GroupUser'
  has_many :account_users, :through => :roles, :source => :role_type, :source_type => 'AccountUser'
  
  
  # INSTANCE BEHAVIOR

  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    UserMailer.deliver_password_reset_instructions(self)  
  end
  
  def account_manager?
    self.account_managers.present?
  end
  
  def account_user?
    self.account_users.present?
  end
  
  def acquainted_with_group_account?(group_account)
    return true if self.admin?
    self.account_managers.any? { |account_manager| account_manager.group_account == group_account }
  end

  def acquainted_with_account?(account)
    return true if self.admin?
    return true if self.account_managers.any? { |account_manager| account_manager.group_account == account.group_account }
    self.account_users.any? { |account_user| account_user.account == account }
  end

  def acquainted_with_campaign?(campaign)
    return true if self.admin?
    return true if self.account_managers.any? { |account_manager| account_manager.group_account == campaign.account.group_account }
    self.account_users.any? { |account_user| account_user.account == campaign.account }
  end
  
  def acquainted_group_accounts
    return GroupAccount.all if self.admin?
    self.account_managers.collect { |account_manager| account_manager.group_account }
  end
  
  def acquainted_accounts
    return Account.all if self.admin?
    (self.account_managers.collect { |account_manager| account_manager.group_account.accounts } << self.account_users.collect { |account_user| account_user.account }).flatten.uniq
  end

  def acquainted_campaigns
    self.acquainted_accounts.collect(&:campaigns).flatten
  end
  
end
