class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new #if no user logged in 
    
    ## User is an ADMIN
    if user.admin?
      can :manage, :all
    else
      ## User is an ACCOUNT MANAGER
      if user.account_manager?
        
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
        can :read, Campaign do |campaign|
          user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
        end
        
      end #account manager
      
      ## User is a USER
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
        
      end #user

    end #if
  end #initialize
  
end