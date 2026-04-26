module Admin
  class SettingsController < BaseController
    # Settings updates aren't tied to a single AR row — skip the generic audit
    # logger and record once per save with our own metadata.
    skip_after_action :log_mutation

    before_action :require_admin!
    before_action :set_tab

    TABS = %w[general security languages].freeze

    def show
      case @tab
      when "languages"
        @site_languages = SiteLanguage.ordered
        @addable_iso_options = SiteLanguage.addable_iso_options
      else
        @definitions = Setting.definitions_for_tab(@tab)
        @values = @definitions.to_h { |key, _| [ key, Setting.get(key) ] }
      end
    end

    def update
      # Only keys defined in the current tab can be updated — prevents an attacker
      # from POSTing arbitrary keys that happen to live in other tabs (or bypassing
      # the whitelist entirely).
      permitted_keys = Setting.definitions_for_tab(@tab).keys
      submitted = params.fetch(:settings, {}).to_unsafe_h.slice(*permitted_keys)

      Setting.bulk_update(submitted) if submitted.any?

      AuditLog.record(
        user:          current_user,
        action:        "update",
        resource:      nil,
        resource_type: "Setting",
        label:         "#{@tab.titleize} settings",
        metadata:      { tab: @tab, keys: submitted.keys },
        ip:            request.remote_ip
      )

      redirect_to admin_settings_tab_path(tab: @tab), notice: "Settings saved."
    end

    private

    def set_tab
      requested = params[:tab].presence || "general"
      @tab = TABS.include?(requested) ? requested : "general"
    end
  end
end
