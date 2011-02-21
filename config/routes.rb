ActionController::Routing::Routes.draw do |map|
  # CUSTOM ROUTES
  map.refresh_accounts    "/accounts/refresh_accounts",         :controller => "accounts",        :action => :refresh_accounts
  map.report_client       "/accounts/:id/report/client",        :controller => "accounts",        :action => :report_client
  map.report_client_pdf   "/accounts/:id/report/client.pdf",    :controller => "accounts",        :action => :report_client, :as => :client
  map.export              "/accounts/export",                   :controller => "accounts",        :action => :export
  map.send_weekly         "/accounts/send_weekly_email/:id",    :controller => "accounts",        :action => :send_weekly_email
  map.login               "/login",                             :controller => "user_sessions",   :action => :new
  map.register            "/register",                          :controller => "users",           :action => :new
  map.submit_cl           "/submissions/:id/submit_cl",         :controller => "submissions",     :action => :submit_cl
  map.submit_call_cl      "/calls/:id/submit_call_cl",          :controller => "calls",           :action => :submit_call_cl
  map.add_customer_lobby  "/accounts/:id/add_customer_lobby",   :controller => "accounts",        :action => :add_customer_lobby
  
  
  map.resources :accounts, :has_many => :campaigns, :member => {:report => :get}
  map.resources :accounts do |account|
    account.resources :campaigns, :member => { :enable => [:put, :post], :index => :get, :orphaned => :get } do |campaign|
      campaign.resources :contact_forms, :member => { :enable => [:put, :post], :index => :get } 
      campaign.resources :google_sem_campaigns, :member => { :enable => [:put, :post], :index => :get, :show => :get } 
    end
  end
  
  map.resources :campaigns, :has_many => :contact_forms, :member => {:lead_matrix => :get}
  map.resources :campaigns do |campaign|
    campaign.resources :contact_forms, :member => { :enable => [:put, :post]} 
  end
  
  
  map.resources :website_visits,  :member => {:global_visitor => :get}
  map.resources :calls,           :member => {:collect => :post}
  map.resources :phone_numbers,   :member => {:connect => :post}
  map.resources :searches,        :only => :index
  map.resources :users
  map.resources :activities
  map.resources :keywords
  map.resources :job_statuses
  map.resources :websites
  map.resources :contact_forms,   :member => {:thank_you => :get, :get_html => :get, :get_iframe => :get}
  
  map.with_options :controller => 'home' do |home|
     home.dashboard 'dashboard', :action => 'dashboard'
  end

  map.resources   :users,         :password_resets
  map.resource    :submission,    :only => [:index, :create, :show]
  map.resource    :person,        :controller => "users"
  map.resource    :user_session
  
  map.root        :controller => "home", :action => "index" 
  map.connect     ':controller/:action/:id'
  map.connect     ':controller/:action/:id.:format'
end
