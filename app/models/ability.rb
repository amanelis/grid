class Ability
  include CanCan::Ability
  
  def initialize(user)
    #user ||= User.new #if no user logged in 
    
    if user.admin?
      can :manage, :all
    else
      #can :read, Account
      
      ## User is an ACCOUNT MANAGER
      if user.roles.account_manager.to_a.present?
        can :read, Account
        can :update, Account do |account|
          account.try(:user) == user
        end
      end
      
      ## User is an ACCOUNT USER
      if user.roles.account_user.to_a.present?
        can :read, Account
      end

    end
  end
  
end