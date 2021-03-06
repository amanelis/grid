# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #include SslRequirement
  include ExceptionNotification::Notifiable

  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  #CanCan rescue errors and access denied
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Ooops, looks like you do not have permissions to view that page!"
    redirect_to dashboard_url
  end

  private
    # pass in the format, and then the path or object you want to render
    # respond() will handle the rest
    # respond("html", dashboard_path, "js", root_url, "xml", @object, .................)
    def respond(*args)
      respond_to do |format|
        Hash[*args].each do |f, r|
          if f.to_s == "html"
            r.nil? ? format.html : format.html {redirect_to r}
          elsif f.to_s == "js"
            r.nil? ? format.js : format.js {redirect_to r}
          elsif f.to_s == "xml"
            r.nil? ? format.xml : format.xml {render :xml => r}
          elsif f.to_s == "json"
            r.nil? ? format.json : format.json {render :json => r}
          end
        end
      end
    end

    def datepicker(*args)
      if params[:to].blank? || params[:from].blank?
        # is our cookie blank?
        if cookies[:start_date].blank?
          cookies[:start_date] = Date.today - 1.month
        else
          cookies[:start_date] = Date.parse(cookies[:start_date])
        end
        # is our cookie blank?
        if cookies[:end_date].blank?
          cookies[:end_date] = Date.today
        else
          cookies[:end_date] = Date.parse(cookies[:end_date])
        end
      else
        begin
          cookies[:start_date] = Date.parse(params[:from])
          cookies[:end_date]   = Date.parse(params[:to])
        rescue
          cookies[:start_date] = Date.today - 1.month
          cookies[:end_date]   = Date.today
          flash[:error] = "The date you entered was incorrect, we set it back to <strong>#{(cookies[:start_date]).to_s(:medium)} to #{cookies[:end_date].to_s(:medium)}</strong> for you."
          respond("html", args.first)
        end
      end
    end

    def require_ssl
      redirect_to :protocol => "https://" unless (request.ssl? or local_request?)
    end

    # resource is refereing to the restful functions that require an instance variable of the controller name
    def load_time_zone
      Time.zone = resource.time_zone
    end

    def no_layout
      render :layout => false
    end

    def check_authorization
      redirect_to root_url unless current_user
    end

    def load_resource_user
      @user = current_user
      @current_user = current_user
    end

    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to dashboard_url
        return false
      end
    end

    def require_admin
      unless current_user && current_user.admin?
        flash[:notice] = "You are not authorized to access this page."
        redirect_to root_path
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end
