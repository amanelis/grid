class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new 
    
    if user.admin?
      can :manage, :all
    else
      
      if user.account_manager?
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
        can :read, Campaign do |campaign|
          user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
        end
        
        can :refresh_accounts, Account
        can :export, Account
        can :report_client, Account
      end 
      
      if user.account_user?
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
        can :read, Campaign do |campaign|
          user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
        end
        can :lead_matrix, Campaign do |campaign|
          user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
        end
      end

    end
  end
end