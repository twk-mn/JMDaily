module Admin
  class SiteLanguagesController < BaseController
    # Skip the generic after_action logger — each action here records its own
    # AuditLog entry with tab-specific context and the correct action name
    # (activate/deactivate would otherwise be logged as "create").
    skip_after_action :log_mutation

    before_action :require_admin!
    before_action :set_site_language, only: [ :update, :destroy, :activate, :deactivate ]

    def create
      code = params.dig(:site_language, :code).to_s
      unless SiteLanguage::ISO_CODES.include?(code)
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "That language code isn't in the supported list."
        return
      end

      if SiteLanguage.exists?(code: code)
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "That language is already added."
        return
      end

      next_position = (SiteLanguage.maximum(:position) || -1) + 1
      @site_language = SiteLanguage.create(
        code:     code,
        position: next_position,
        active:   true,
        deletable: true
      )

      if @site_language.persisted?
        audit("create", @site_language, { code: @site_language.code })
        redirect_to admin_settings_tab_path(tab: "languages"),
                    notice: "#{@site_language.name} added."
      else
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: @site_language.errors.full_messages.to_sentence
      end
    end

    def update
      # Only name/native_name/flag_emoji are editable — code is identity and
      # deletable/active have dedicated endpoints with safety checks.
      if @site_language.update(edit_params)
        audit("update", @site_language, edit_params.to_h)
        redirect_to admin_settings_tab_path(tab: "languages"),
                    notice: "#{@site_language.name} updated."
      else
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: @site_language.errors.full_messages.to_sentence
      end
    end

    def activate
      unless @site_language.deletable
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "That language is always active."
        return
      end

      @site_language.update!(active: true)
      audit("update", @site_language, { active: true })
      redirect_to admin_settings_tab_path(tab: "languages"),
                  notice: "#{@site_language.name} is now active."
    end

    def deactivate
      unless @site_language.deactivatable?
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "That language cannot be deactivated."
        return
      end

      @site_language.update!(active: false)
      audit("update", @site_language, { active: false })
      redirect_to admin_settings_tab_path(tab: "languages"),
                  notice: "#{@site_language.name} is now hidden. Existing content is retained until you purge."
    end

    def destroy
      # Typed-confirmation gate — the UI asks the admin to type the language
      # code; we require it here too so a direct API call can't bypass it.
      unless params[:confirm].to_s == @site_language.code
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "Purge not confirmed — type the language code to proceed."
        return
      end

      unless @site_language.purgeable?
        redirect_to admin_settings_tab_path(tab: "languages"),
                    alert: "Deactivate the language before purging."
        return
      end

      code = @site_language.code
      name = @site_language.name

      # Wrap in a transaction so partial purges can't leave orphaned rows behind.
      ActiveRecord::Base.transaction do
        ArticleTranslation.where(locale: code).delete_all
        NewsletterIssue.where(locale: code).delete_all if defined?(NewsletterIssue)
        @site_language.destroy!
      end

      audit("destroy", nil, { code: code, name: name }, resource_type: "SiteLanguage", label: name)
      redirect_to admin_settings_tab_path(tab: "languages"),
                  notice: "#{name} and all its translations have been permanently removed."
    end

    def reorder
      ids = Array(params[:ordered_ids]).map(&:to_i)
      SiteLanguage.transaction do
        ids.each_with_index do |id, index|
          SiteLanguage.where(id: id).update_all(position: index)
        end
      end
      SiteLanguage.new.send(:bust_cache) # bump version so other processes see it

      respond_to do |format|
        format.json { render json: { ok: true } }
        format.html { redirect_to admin_settings_tab_path(tab: "languages") }
      end
    end

    private

    def set_site_language
      @site_language = SiteLanguage.find(params[:id])
    end

    def edit_params
      params.require(:site_language).permit(:name, :native_name, :flag_emoji)
    end

    def audit(action, resource, metadata, resource_type: nil, label: nil)
      AuditLog.record(
        user:          current_user,
        action:        action,
        resource:      resource,
        resource_type: resource_type,
        label:         label,
        metadata:      metadata,
        ip:            request.remote_ip
      )
    end
  end
end
