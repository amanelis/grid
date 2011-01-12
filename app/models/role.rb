class Role < ActiveRecord::Base
  belongs_to :user
  belongs_to :role_type, :polymorphic => true
  
  named_scope :account_manager, :conditions => {:role_type_type => AccountManager.name}
  named_scope :account_user, :conditions => {:role_type_type => AccountUser.name}
  
end