class AddSomeMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index 'account_users', 'account_id'
    add_index 'website_visits', 'visitor_id'
    add_index 'account_managers', 'group_account_id'
    add_index 'accounts', 'group_account_id'
    add_index 'accounts', 'account_manager_id'
    add_index 'roles', 'user_id'
    add_index 'roles', 'role_type_id'
    add_index 'group_accounts', 'salesforce_id'
  end

  def self.down
    remove_index 'account_users', 'account_id'
    remove_index 'website_visits', 'visitor_id'
    remove_index 'account_managers', 'group_account_id'
    remove_index 'accounts', 'group_account_id'
    remove_index 'accounts', 'account_manager_id'
    remove_index 'roles', 'user_id'
    remove_index 'roles', 'role_type_id'
    remove_index 'group_accounts', 'salesforce_id'
  end
end
