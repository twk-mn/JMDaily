class RegenerateSitemapJob < ApplicationJob
  queue_as :default

  def perform
    SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}"
    SitemapGenerator::Sitemap.compress = true
    SitemapGenerator::Interpreter.run(config_file: Rails.root.join("config/sitemap.rb").to_s)
    Rails.logger.info("[RegenerateSitemapJob] Sitemap regenerated")
  rescue => e
    Rails.logger.error("[RegenerateSitemapJob] Failed: #{e.message}")
    raise
  end
end
