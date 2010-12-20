ActionController::Routing::Routes.draw do |map|
  # Custom Routes
  map.admin "/admin", :controller => 'admin_area', :action => 'index'
  map.refresh_accounts "/admin/accounts/refresh_accounts", :controller => "admin/accounts", :action => :refresh_accounts
  map.report_client "/admin/accounts/:id/report/client", :controller => "admin/accounts", :action => :report_client
  map.report_client_pdf "/admin/accounts/:id/report/client.pdf", :controller => "admin/accounts", :action => :report_client, :as => :client
  map.export "/admin/accounts/export", :controller => "admin/accounts", :action => :export
  # map.weekly_report "/admin/notifiers/weekly_report/:id", :controller => "admin/notifiers", :action => :weekly_report
  
  map.namespace :admin do |admin|
    admin.resources :accounts, :member => {:report => :get}
    admin.resources :users
    admin.resources :campaigns, :member => {:lead_matrix => :get}
    admin.resources :activities
    admin.resources :keywords
    admin.resources :job_statuses
    admin.resources :websites
    admin.resources :website_visits, :member => {:global_visitor => :get}
    admin.resources :searches, :only => :index
  end

  map.with_options :controller => 'home' do |home|
     home.dashboard 'dashboard', :action => 'dashboard'
  end

  map.resource :person, :controller => "users"
  map.resources :users, :password_resets
  map.resource :user_session
  map.resource :submission, :only => [:index, :create, :show]
  map.root :controller => "home", :action => "index" # optional, this just sets the root route

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
