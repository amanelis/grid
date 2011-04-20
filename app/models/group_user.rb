class GroupUser < ActiveRecord::Base
  include RoleTypeMixin
  
  belongs_to :group_account
  has_many :accounts, :foreign_key => "account_manager_id"
  has_many :channels, :foreign_key => "channel_manager_id"

  validate :unique_role?
  
  
  # PREDICATES
  
  def unique?
    self.role.user.group_users.none? { |group_user| group_user.group_account == self.group_account }
  end
  
  def account_manager?
    self.accounts.present?
  end
  
  def valid_account_manager_information?
    valid_manager_information?
  end

  def valid_channel_manager_information?
    valid_manager_information?
  end
  
  
  # PRIVATE BEHAVIOR
  
  private
  
  def valid_manager_information?
    return false unless self.name.present?
    return false unless self.phone_number.present?
    return false unless self.email.present?
    true
  end
  
  def unique_role?
    unless unique?
      errors.add_to_base("A group user role already exists for this user and group account")
    end
  end
 
end
