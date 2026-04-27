module CdnUrlRewriter
  module_function

  # Rewrites an S3-style object URL so it points at the configured CDN host.
  #
  # Cloudflare R2 custom domains map directly to the bucket root, so when the
  # source URL is path-style (e.g. https://acct.r2.cloudflarestorage.com/bucket/key.jpg)
  # the leading "/bucket" segment is dropped before joining with the CDN host.
  # Virtual-host-style URLs (no bucket in the path) are joined as-is.
  def call(url, bucket_name:, cdn_host:)
    return url if cdn_host.to_s.strip.empty?

    uri = URI.parse(url)
    path = uri.path.to_s
    bucket_prefix = "/#{bucket_name}"
    path = path.delete_prefix(bucket_prefix) if bucket_name.present? && path.start_with?("#{bucket_prefix}/")
    suffix = uri.query.present? ? "?#{uri.query}" : ""
    "#{cdn_host.to_s.chomp('/')}#{path}#{suffix}"
  rescue URI::InvalidURIError
    url
  end
end
