class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new #if no user logged in 
    
    if user.admin?
      can :manage, :all
    else
      # Can update account user owns
      can :update, Account do |account|
        account.try(:user) == user
      end
    end
  end
  
end