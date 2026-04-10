module Admin
  class AuditLogsController < BaseController
    before_action :require_admin!

    def index
      @audit_logs = AuditLog.recent.includes(:user).limit(200)
    end
  end
end
