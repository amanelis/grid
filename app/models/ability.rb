class Ability
  include CanCan::Ability
  
  def initialize(user)
    #user ||= User.new #if no user logged in 
    
    if user.admin?
      can :manage, :all
    else
      ## User is an ACCOUNT MANAGER
      if user.roles.account_manager.to_a.present?
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
      end
      
      ## User is an ACCOUNT USER or just USER
      if user.roles.account_user.to_a.present?
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
      end

    end #if
  end #initialize
  
end