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

  BROWSER_LOCALES = %w[en ja].freeze

  def set_locale
    locale = params[:locale] ||
             cookies[:locale] ||
             browser_preferred_locale ||
             I18n.default_locale.to_s

    locale = I18n.default_locale.to_s unless BROWSER_LOCALES.include?(locale)
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
    accept.scan(/[a-z]{2}/).find { |l| BROWSER_LOCALES.include?(l) }
  end
end
