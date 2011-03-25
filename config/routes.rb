ActionController::Routing::Routes.draw do |map|
  # CUSTOM ROUTES
  map.report_client       "/accounts/:id/report/client",                  :controller => "accounts",        :action => :report_client
  map.report_client_pdf   "/accounts/:id/report/client.pdf",              :controller => "accounts",        :action => :report_client, :as => :client
  map.send_weekly         "/accounts/send_weekly_email/:id",              :controller => "accounts",        :action => :send_weekly_email
  map.login               "/login",                                       :controller => "user_sessions",   :action => :new
  map.logout              "/logout",                                      :controller => "user_sessions",   :action => :destroy
  map.register            "/register",                                    :controller => "users",           :action => :new
                                                                          
  # Twilio routing                                                                 
  map.connect_number_api  "/api/v1/calls/:encoded_number/connect",        :controller => "api/v1/calls",       :action => :connect
  map.collect_number_api  "/api/v1/calls/:encoded_number/complete",       :controller => "api/v1/calls",       :action => :complete
                                                                                              
  map.get_html            "/api/v1/forms/:form_id/get_html",              :controller => "api/v1/forms",       :action => :get_html
  map.get_iframe          "/api/v1/forms/:form_id/get_iframe",            :controller => "api/v1/forms",       :action => :get_iframe
  map.thank_you           "/api/v1/forms/:form_id/thank_you",             :controller => "api/v1/forms",       :action => :thank_you
  map.form_submit         "/api/v1/forms/submit",                         :controller => "api/v1/forms",       :action => :submission, :conditions => { :method => :post }
                                                                                              
  map.form_submit_old     "/submission",                                  :controller => "api/v1/forms",       :action => :submission, :conditions => { :method => :post }
  map.form_thank_old      "/contact_forms/:id/thank_you",                 :controller => "api/v1/forms",       :action => :thank_you
  # CUSTOM ROUTES
  
  map.resources :accounts do |account|
    account.resources :users
    account.resources :channels, :name_prefix => "" do |channel|
      channel.resources :campaigns do |campaign|
        campaign.resources :phone_numbers
        campaign.resources :contact_forms
        campaign.resources :keywords
      end
    end
  end
  
  map.namespace(:api) do |api|
    api.resources :calls
    api.resources :forms
  end
  
  map.resources :phone_numbers
  map.resources :user_sessions

  map.resources   :contact_forms,   :member => {:thank_you => :get, :get_html => :get, :get_iframe => :get}
  map.resources   :website_visits,  :member => {:global_visitor => :get}
  map.resources   :calls,           :member => {:collect => :post}
  map.resources   :phone_numbers,   :member => {:connect => :post}
  map.resources   :searches, :activities, :keywords, :job_statuses, :websites
  map.resources   :users,         :password_resets
  map.resource    :submission,    :only => [:index, :create, :show]
  
  map.with_options :controller => 'home' do |home|
    home.dashboard 'dashboard', :action => 'dashboard'
  end
  
  # End point route
  map.root :controller => "home", :action => "index" 
end
