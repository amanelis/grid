class Ability
  include CanCan::Ability
  
  def initialize(user)
    user ||= User.new
    
    if user.admin?
      can :manage, :all
    else
      # Account Authorization
      can :create, Account if user.manipulable_group_accounts.present?
      
      can :read, Account do |account|
        user.acquainted_with_account?(account)
      end
      can :edit, Account do |account|
        user.can_manipulate_account?(account)
      end
      can :update, Account do |account|
        user.can_manipulate_account?(account)
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
      
      # Keyword Authorization
      can :read, Keyword do |keyword|
        user.acquainted_with_keyword?(keyword)
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
          can :edit, User
          can :update, User
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
      
      
      can :refresh_accounts, Account if user.admin?
      can :report_client, Account do |account|
        user.acquainted_with_account?(account)
      end
      can :read, Activity if user.group_user?
      can :edit, Activity if user.group_user?
      can :update, Activity if user.group_user?
    end
    
  end
end