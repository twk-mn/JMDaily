module Admin
  class BaseController < ApplicationController
    include Pagy::Method

    SESSION_TIMEOUT = SiteConfig::ADMIN_SESSION_TIMEOUT

    before_action :require_login
    before_action :check_session_timeout
    before_action :refresh_last_active_at
    after_action  :log_mutation, if: :auditable_request?

    layout "admin"

    private

    def require_login
      unless current_user
        redirect_to admin_login_path, alert: "You must be logged in."
      end
    end

    def require_admin!
      unless current_user&.admin?
        redirect_to admin_articles_path, alert: "You do not have permission to do that."
      end
    end

    def auditable_request?
      request.post? || request.patch? || request.put? || request.delete?
    end

    def log_mutation
      return unless current_user
      return unless response.successful? || response.redirect?

      resource = find_auditable_resource
      return unless resource

      action = case request.method
      when "POST"   then "create"
      when "PATCH", "PUT" then "update"
      when "DELETE" then "destroy"
      end

      AuditLog.record(
        user:     current_user,
        action:   action,
        resource: resource,
        ip:       request.remote_ip
      )
    end

    def find_auditable_resource
      # Each controller sets an instance variable matching its model — find it by convention.
      # e.g. ArticlesController sets @article, AdsController sets @ad, etc.
      resource_name = controller_name.singularize
      instance_variable_get(:"@#{resource_name}")
    end

    def check_session_timeout
      return unless current_user

      last_active = session[:last_active_at]
      if last_active && Time.zone.parse(last_active.to_s) < SESSION_TIMEOUT.ago
        reset_session
        redirect_to admin_login_path, alert: "Your session expired. Please log in again."
      end
    end

    def refresh_last_active_at
      session[:last_active_at] = Time.current.to_s if current_user
    end
  end
end
