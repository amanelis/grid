ActionController::Routing::Routes.draw do |map|
  # CUSTOM ROUTES
  map.refresh_accounts    "/accounts/refresh_accounts",         :controller => "accounts",        :action => :refresh_accounts
  map.report_client       "/accounts/:id/report/client",        :controller => "accounts",        :action => :report_client
  map.report_client_pdf   "/accounts/:id/report/client.pdf",    :controller => "accounts",        :action => :report_client, :as => :client
  map.export              "/accounts/export",                   :controller => "accounts",        :action => :export
  map.send_weekly         "/accounts/send_weekly_email/:id",    :controller => "accounts",        :action => :send_weekly_email
  
  map.resources :accounts,        :member => {:report => :get}
  map.resources :campaigns,       :member => {:lead_matrix => :get}
  map.resources :website_visits,  :member => {:global_visitor => :get}
  map.resources :searches,        :only => :index
  map.resources :users
  map.resources :activities
  map.resources :keywords
  map.resources :job_statuses
  map.resources :websites
  map.resources :contact_forms
  map.resources :calls, :member => {:collect => :post}
  map.resources :phone_numbers, :member => {:connect => :post}
  
  map.with_options :controller => 'home' do |home|
     home.dashboard 'dashboard', :action => 'dashboard'
  end

  map.resources   :users,       :password_resets
  map.resource    :submission,  :only => [:index, :create, :show]
  map.resource    :person,      :controller => "users"
  map.resource    :user_session
  
  map.root        :controller => "home", :action => "index" 
  map.connect     ':controller/:action/:id'
  map.connect     ':controller/:action/:id.:format'
end
