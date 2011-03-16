class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :roles
  
  has_many :group_users, :through => :roles, :source => :role_type, :source_type => 'GroupUser'
  has_many :account_users, :through => :roles, :source => :role_type, :source_type => 'AccountUser'
  
  
  # INSTANCE BEHAVIOR

  def deliver_password_reset_instructions!
    reset_perishable_token!  
    UserMailer.deliver_password_reset_instructions(self)  
  end
  
  def group_user?
    self.group_users.present?
  end
  
  def account_user?
    self.account_users.present?
  end
  
  def acquainted_with_group_account?(group_account)
    self.acquainted_group_accounts.include?(group_account)
  end

  def can_manipulate_group_account?(group_account)
    self.manipulable_group_accounts.include?(group_account)
  end

  def acquainted_with_account?(account)
    self.acquainted_accounts.include?(account)
  end

  def can_manipulate_account?(account)
    self.manipulable_accounts.include?(account)
  end

  def acquainted_with_campaign?(campaign)
    self.acquainted_campaigns.include?(campaign)
  end
  
  def can_manipulate_campaign?(campaign)
    self.manipulable_campaigns.include?(campaign)
  end
  
  def acquainted_with_keyword?(keyword)
    self.acquainted_keywords.include?(keyword)
  end
  
  def can_manipulate_keyword?(keyword)
    self.manipulable_keywords.include?(keyword)
  end
  
  def acquainted_group_accounts
    self.admin? ? GroupAccount.all : retrieve_group_accounts_from_group_users(self.group_users)
  end
  
  def manipulable_group_accounts
    self.admin? ? GroupAccount.all : retrieve_group_accounts_from_group_users(self.group_users.select(&:manipulator?))
  end
  
  def acquainted_accounts
    self.admin? ? Account.all : (retrieve_accounts_from_group_accounts(self.acquainted_group_accounts) << retrieve_accounts_from_account_users(self.account_users)).flatten.uniq
  end

  def manipulable_accounts
    self.admin? ? Account.all : (retrieve_accounts_from_group_accounts(self.manipulable_group_accounts) << retrieve_accounts_from_account_users(self.account_users.select(&:manipulator?))).flatten.uniq
  end

  def acquainted_campaigns
    retrieve_campaigns_from_accounts(self.acquainted_accounts)
  end

  def manipulable_campaigns
    retrieve_campaigns_from_accounts(self.manipulable_accounts)
  end
  
  def acquainted_keywords
    retrieve_keywords_from_campaigns(self.acquainted_campaigns)
  end

  def manipulable_keywords
    retrieve_keywords_from_campaigns(self.manipulable_campaigns)
  end
  
  def manipulable_users
    manipulable_role_types.collect(&:user).uniq
  end
  
  def manipulable_role_types_for(user)
    user.roles.collect(&:role_type).select { |role_type| manipulable_role_types.include?(role_type) }
  end

  
  # PRIVATE BEHAVIOR
  
  private
  
  def retrieve_group_accounts_from_group_users(group_users)
    group_users.collect(&:group_account)
  end
  
  def retrieve_accounts_from_group_accounts(group_accounts)
    group_accounts.collect(&:accounts).flatten
  end
  
  def retrieve_accounts_from_account_users(account_users)
    account_users.collect(&:account)
  end
  
  def retrieve_campaigns_from_accounts(accounts)
    accounts.collect(&:campaigns).flatten
  end
  
  def retrieve_keywords_from_campaigns(campaigns)
    campaigns.select(&:is_seo?).collect { |campaign| campaign.campaign_style.keywords }.flatten
  end
  
  def manipulable_role_types
    @manipulable_role_types ||= (self.manipulable_group_accounts.collect { |manipulable_group_account| manipulable_group_account.group_users } << self.manipulable_accounts.collect { |manipulable_account| manipulable_account.account_users }).flatten
  end
    
end
