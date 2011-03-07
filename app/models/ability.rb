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
            can :create, BasicChannel
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
        
        can :update, Campaign do |campaign|
           if user.can_manipulate_campaign?(campaign) 
             can :update, Campaign
           end
        end
        ########## Manipulator Method #################
        
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
        
        ########## Manipulator Method #################
        can :manipulate_account, Account do |account|
          user.can_manipulate_account?(account) ? (can :create, Campaign) : false
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
        can :update, Campaign do |campaign|
           if user.can_manipulate_campaign?(campaign) 
             can :update, Campaign
           end
        end
        ########## Manipulator Method #################
        
        can :report_client, Account
      end

    end
  end
end