class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new 
    
    if user.admin?
      can :manage, :all
    else
      
      if user.group_user?
        can :read, Account do |account|
          user.acquainted_with_account?(account)
        end
        can :read, Campaign do |campaign|
          user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
        end
        can :read, Website do |website|
          user.acquainted_accounts.collect(&:websites).flatten.include?(website)
        end
        
        can :manipulate_campaign, Account do |account|
          user.can_manipulate_account?(account) ? (can :create, Campaign) : false
        end
        
        
        
        can :export, Account
        can :refresh_accounts, Account
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
        can :read, Website do |website|
          user.acquainted_accounts.collect(&:websites).flatten.include?(website)
        end
        can :read, WebsiteVisit do |website_visit|
          user.acquainted_accounts.collect(&:websites).flatten.include?(website_visit.website)
        end
        
        can :report_client, Account
      end

    end
  end
end