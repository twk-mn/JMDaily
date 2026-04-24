class ApplicationController < ActionController::Base
  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  private

  def set_locale
    # Keep I18n.available_locales in sync with the SiteLanguage table so newly-
    # added languages are accepted by I18n without requiring a server restart.
    SiteLanguage.sync_i18n!

    active_codes = SiteLanguage.active_codes

    # Routes accept any /[a-z]{2,3}/ locale segment; 404 explicitly when the
    # requested locale isn't currently active so deactivated languages don't
    # fall through to default-locale content (which would be confusing).
    # Only route-segment locales trigger a 404 — a ?locale= query param on an
    # unscoped endpoint (e.g. /feed) should fall back gracefully instead.
    route_locale = request.path_parameters[:locale]
    if route_locale.present? && !active_codes.include?(route_locale.to_s)
      raise ActiveRecord::RecordNotFound
    end

    locale = params[:locale] ||
             cookies[:locale] ||
             browser_preferred_locale ||
             I18n.default_locale.to_s

    locale = I18n.default_locale.to_s unless active_codes.include?(locale)
    I18n.locale = locale

    # Persist preference for one year
    cookies[:locale] = { value: I18n.locale, expires: 1.year, same_site: :lax }
  end

  # Injects :locale into every url_for / *_path / *_url call automatically,
  # so existing article_path(article) calls gain the locale segment for free.
  def default_url_options
    { locale: I18n.locale }
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def browser_preferred_locale
    accept = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
    active = SiteLanguage.active_codes
    accept.scan(/[a-z]{2}/).find { |l| active.include?(l) }
  end
end
