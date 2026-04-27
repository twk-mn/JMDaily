require 'rails_helper'

RSpec.describe CdnUrlRewriter do
  describe ".call" do
    let(:bucket) { "jmdaily-production" }
    let(:cdn) { "https://assets.jmdaily.com" }

    it "rewrites a path-style R2 URL to the CDN host, dropping the bucket prefix" do
      original = "https://abc123.r2.cloudflarestorage.com/jmdaily-production/variants/foo/bar.webp"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: cdn))
        .to eq("https://assets.jmdaily.com/variants/foo/bar.webp")
    end

    it "rewrites a virtual-host-style URL by replacing the host" do
      original = "https://jmdaily-production.abc123.r2.cloudflarestorage.com/key.jpg"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: cdn))
        .to eq("https://assets.jmdaily.com/key.jpg")
    end

    it "preserves a query string on the source URL when rewriting" do
      original = "https://abc123.r2.cloudflarestorage.com/jmdaily-production/key.jpg?v=2"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: cdn))
        .to eq("https://assets.jmdaily.com/key.jpg?v=2")
    end

    it "trims a trailing slash on the CDN host so paths don't double-slash" do
      original = "https://abc123.r2.cloudflarestorage.com/jmdaily-production/key.jpg"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: "https://assets.jmdaily.com/"))
        .to eq("https://assets.jmdaily.com/key.jpg")
    end

    it "returns the original URL when cdn_host is blank" do
      original = "https://abc123.r2.cloudflarestorage.com/jmdaily-production/key.jpg"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: ""))
        .to eq(original)
    end

    it "returns the original URL when the input cannot be parsed" do
      bogus = "not a url at all"
      expect(described_class.call(bogus, bucket_name: bucket, cdn_host: cdn))
        .to eq(bogus)
    end

    it "leaves the path alone when it does not start with the bucket prefix" do
      original = "https://abc123.r2.cloudflarestorage.com/some/other/path.jpg"
      expect(described_class.call(original, bucket_name: bucket, cdn_host: cdn))
        .to eq("https://assets.jmdaily.com/some/other/path.jpg")
    end
  end
end
