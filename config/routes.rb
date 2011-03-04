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
  #map.get_iframe          "/accounts/:id/campaigns/:campaign_id/contact_forms/:contact_form_id/get_iframe", :controller => "contact_forms", :action => :get_iframe
  #map.get_html            "/accounts/:id/campaigns/:campaign_id/contact_forms/:contact_form_id/get_html", :controller => "contact_forms", :action => :get_html
  
  map.resources :accounts do |account|
    account.resources :basic_channels, :name_prefix => "" do |basic_channels|
      basic_channels.resources :campaigns
    end
  end

  map.resources   :contact_forms,   :member => {:thank_you => :get, :get_html => :get, :get_iframe => :get}
  map.resources   :website_visits,  :member => {:global_visitor => :get}
  map.resources   :calls,           :member => {:collect => :post}
  map.resources   :phone_numbers,   :member => {:connect => :post}
  map.resources   :searches, :activities, :keywords, :job_statuses, :websites
  map.resources   :users,         :password_resets
  map.resource    :submission,    :only => [:index, :create, :show]
  map.resource    :person,        :controller => "users"
  map.resource    :user_session
  
  
  map.with_options :controller => 'home' do |home|
    home.dashboard 'dashboard', :action => 'dashboard'
  end
  map.root        :controller => "home", :action => "index" 
end
