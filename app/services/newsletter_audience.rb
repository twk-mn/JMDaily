require "net/http"
require "uri"
require "json"

# Sync confirmed newsletter subscribers to an external audience list (ESP).
#
# Settings (admin → Settings → Newsletter):
#   newsletter_provider     — "none" (default) or "resend"
#   newsletter_api_key      — provider API key (treated as a secret)
#   newsletter_audience_id  — audience/list ID at the provider
#
# Sync is enabled only when the provider is non-default AND both the API key
# and audience ID are set. A misconfigured admin can't break confirmation —
# all calls fail-closed and log instead of raising into the request flow.
module NewsletterAudience
  PROVIDERS = %w[none resend].freeze
  RESEND_BASE_URL = "https://api.resend.com".freeze

  class << self
    # Test hook. When non-nil in test env, sync calls return this value
    # without making any HTTP request. Specs flip it to true/false to
    # exercise both the success and failure paths.
    attr_accessor :test_sync_result

    def provider
      raw = Setting.get("newsletter_provider").to_s
      PROVIDERS.include?(raw) ? raw : "none"
    end

    def api_key
      Setting.get("newsletter_api_key").to_s
    end

    def audience_id
      Setting.get("newsletter_audience_id").to_s
    end

    def configured?
      provider != "none" && api_key.present? && audience_id.present?
    end

    def subscribe(subscriber)
      dispatch(:subscribe, subscriber)
    end

    def unsubscribe(subscriber)
      dispatch(:unsubscribe, subscriber)
    end

    private

    def dispatch(action, subscriber)
      return false unless configured?
      return test_sync_result unless test_sync_result.nil? if Rails.env.test?

      case provider
      when "resend" then send("resend_#{action}", subscriber)
      else false
      end
    rescue StandardError => e
      Rails.logger.warn("[newsletter_audience] #{action} failed: #{e.class}: #{e.message}")
      false
    end

    def resend_subscribe(subscriber)
      response = http_request(
        Net::HTTP::Post,
        "#{RESEND_BASE_URL}/audiences/#{audience_id}/contacts",
        body: { email: subscriber.email, unsubscribed: false }
      )
      [ "200", "201" ].include?(response.code)
    end

    def resend_unsubscribe(subscriber)
      response = http_request(
        Net::HTTP::Patch,
        "#{RESEND_BASE_URL}/audiences/#{audience_id}/contacts/#{CGI.escape(subscriber.email)}",
        body: { unsubscribed: true }
      )
      [ "200" ].include?(response.code)
    end

    def http_request(method_class, url, body:)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 3
      http.read_timeout = 5

      request = method_class.new(uri.request_uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json
      http.request(request)
    end
  end
end
