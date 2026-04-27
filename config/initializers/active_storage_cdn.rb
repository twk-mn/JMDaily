# When R2_PUBLIC_URL is set, rewrite Active Storage public URLs so blobs are
# served via the CDN host (e.g. assets.jmdaily.com) instead of the R2 origin
# endpoint. This only affects services with `public: true`; signed/proxied
# URLs go through the standard Rails routes.
return if ENV["R2_PUBLIC_URL"].to_s.strip.empty?

Rails.application.config.after_initialize do
  next unless defined?(ActiveStorage::Service::S3Service)

  cdn_host = ENV["R2_PUBLIC_URL"]

  ActiveStorage::Service::S3Service.prepend(Module.new do
    define_method(:public_url) do |key, **client_opts|
      CdnUrlRewriter.call(super(key, **client_opts),
                          bucket_name: bucket.name,
                          cdn_host: cdn_host)
    end
  end)
end
