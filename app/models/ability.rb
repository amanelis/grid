class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new 
    
    if user.admin?
      can :manage, :all
    else
      # Account Authorization
      can :read, Account do |account|
        user.acquainted_with_account?(account)
      end
      
      # Campaign Authorization
      can :read, Campaign do |campaign|
        user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
      end
      can :edit, Campaign do |campaign|
        user.can_manipulate_campaign?(campaign)
      end
      can :update, Campaign do |campaign|
        user.can_manipulate_campaign?(campaign)
      end
      can :destroy, Campaign do |campaign|
        user.can_manipulate_campaign?(campaign)
      end
      
      # Channel Authorization
      can :read, Channel do |channel|
        user.acquainted_with_account?(channel.account)
      end
      can :edit, Channel do |channel|
        user.can_manipulate_account?(channel.account)
      end
      can :update, Channel do |channel|
        user.can_manipulate_account?(channel.account)
      end
      can :destroy, Channel do |channel|
        user.can_manipulate_account?(channel.account)
      end
            
      # Custom Authorization
      can :lead_matrix, Campaign do |campaign|
        user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
      end
      can :orphaned, Campaign do |campaign|
        user.acquainted_accounts.collect(&:campaigns).flatten.include?(campaign)
      end
      can :read, Website do |website|
        user.acquainted_accounts.collect(&:websites).flatten.include?(website)
      end
      can :read, WebsiteVisit do |website_visit|
        user.acquainted_accounts.collect(&:websites).flatten.include?(website_visit.website)
      end
      
      ########## Manipulator Method #################
      can :manipulate_account, Account do |account|
        if user.can_manipulate_account?(account) 
          can :create, Campaign
          can :new, Campaign
          
          can :create, Channel
          can :new, Channel
          
          can :create, User
          can :new, User
        else
          false
        end
      end
      
      can :manipulate_campaign, Campaign do |campaign|
        if user.can_manipulate_campaign?(campaign) 
          can :edit, Campaign
          can :update, Campaign
          can :read, Campaign
          can :create, ContactForm
        else
          false
        end
      end
      ########## Manipulator Method #################
      
      can :export, Account
      can :refresh_accounts, Account
      can :report_client, Account
      can :read, Channel
    end
    
  end
end