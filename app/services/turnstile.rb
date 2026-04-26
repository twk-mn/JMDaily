require "net/http"
require "uri"
require "json"

# Cloudflare Turnstile verification.
#
# Settings (admin → Settings → Security):
#   turnstile_site_key       — public widget key
#   turnstile_secret_key     — server verification key
#   turnstile_on_<form_key>  — booleans, one per protected form
#
# A form is "enabled" only when the matching toggle is on AND both keys are
# present — that way a half-configured admin can't lock visitors out of forms.
module Turnstile
  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze
  RESPONSE_PARAM = "cf-turnstile-response".freeze

  # Form keys this app guards. Add a new entry here + a matching
  # turnstile_on_<key> Setting definition to extend coverage.
  FORMS = %w[comments contact tips newsletter].freeze

  class << self
    # Test hook. When non-nil in test env, verify returns this value without
    # making any HTTP request. Specs flip it to true/false to exercise both
    # the success and failure paths.
    attr_accessor :test_verification_result

    def site_key
      Setting.get("turnstile_site_key").to_s
    end

    def secret_key
      Setting.get("turnstile_secret_key").to_s
    end

    def configured?
      site_key.present? && secret_key.present?
    end

    # True when this specific form should require Turnstile right now.
    # Returns false if keys aren't configured, even if the toggle is on, so
    # a misconfigured admin can't silently break public forms.
    def enabled_for?(form_key)
      return false unless FORMS.include?(form_key.to_s)
      return false unless configured?

      Setting.get("turnstile_on_#{form_key}") == true
    end

    # Sends the token to Cloudflare's siteverify endpoint and returns true
    # only if the response is a JSON object with "success": true. Network
    # errors and parse failures fall back to false (fail-closed).
    def verify(token, remote_ip = nil)
      return test_verification_result unless test_verification_result.nil? if Rails.env.test?
      return false if token.blank? || secret_key.blank?

      response = post_form(
        SITEVERIFY_URL,
        secret:   secret_key,
        response: token,
        remoteip: remote_ip.to_s
      )
      payload = JSON.parse(response.body)
      payload["success"] == true
    rescue StandardError => e
      Rails.logger.warn("[turnstile] verify failed: #{e.class}: #{e.message}")
      false
    end

    private

    def post_form(url, params)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 3
      http.read_timeout = 5
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
      http.request(request)
    end
  end
end
