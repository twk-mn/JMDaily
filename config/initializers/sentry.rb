Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  # Only enable when DSN is configured (prevents noise in dev/test)
  config.enabled_environments = %w[production]

  # Capture 10% of transactions for performance monitoring
  config.traces_sample_rate = 0.1

  # Capture user context (id only — no PII)
  config.before_send = lambda do |event, _hint|
    event
  end
end
