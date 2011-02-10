class Role < ActiveRecord::Base
  belongs_to :user
  belongs_to :role_type, :polymorphic => true
  
  named_scope :group_users, :conditions => {:role_type_type => GroupUser.name}
  named_scope :account_users, :conditions => {:role_type_type => AccountUser.name}
  
  def is_group_user?
    self.role_type.instance_of?(GroupUser)
  end
  
  def is_account_user?
    self.role_type.instance_of?(AccountUser)
  end
  
end
