class RefactorAccountManagerIntoGroupUser < ActiveRecord::Migration
  def self.up
    rename_table(:account_managers, :group_users)
    Role.all.each { |role| role.update_attribute(:role_type_type, 'GroupUser') if role.role_type_type == 'AccountManager' }
  end

  def self.down
    rename_table(:group_users, :account_managers)
    Role.all.each { |role| role.update_attribute(:role_type_type, 'AccountManager') if role.role_type_type == 'GroupUser' }
  end
end
