module Admin
  class BaseController < ApplicationController
    before_action :require_login
    layout "admin"

    private

    def require_login
      unless current_user
        redirect_to admin_login_path, alert: "You must be logged in."
      end
    end
  end
end
