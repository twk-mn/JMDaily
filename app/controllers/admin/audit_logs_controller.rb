module Admin
  class AuditLogsController < BaseController
    before_action :require_admin!

    def index
      @pagy, @audit_logs = pagy(:offset, AuditLog.recent.includes(:user), limit: 50)
    end
  end
end
