class Role < ActiveRecord::Base
  belongs_to :user
  belongs_to :role_type, :polymorphic => true
  
  named_scope :group_users, :conditions => {:role_type_type => GroupUser.name}
  named_scope :account_users, :conditions => {:role_type_type => AccountUser.name}
  
end
