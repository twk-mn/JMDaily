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

  # Canonical URL for the current request (no query string). Pages can override
  # by setting `content_for(:canonical_url, ...)` in the view.
  def canonical_url_for_current_request
    "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}#{request.path}"
  end
  helper_method :canonical_url_for_current_request

  # Map of locale → URL for hreflang link tags. The default substitutes the
  # locale segment in the current path; controllers with per-locale slugs
  # (notably Articles) override this to use the per-translation URL.
  def alternate_locale_urls
    return {} unless params[:locale].present?
    host = "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}"
    SiteLanguage.active_codes.each_with_object({}) do |code, h|
      h[code] = "#{host}#{request.path.sub(/\A\/[a-z]{2,3}/, "/#{code}")}"
    end
  end
  helper_method :alternate_locale_urls

  def browser_preferred_locale
    accept = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
    active = SiteLanguage.active_codes
    accept.scan(/[a-z]{2}/).find { |l| active.include?(l) }
  end
end
