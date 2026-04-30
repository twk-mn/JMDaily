require 'rails_helper'
require 'erb'
require 'yaml'

RSpec.describe "config/storage.yml — cloudflare_r2 service" do
  ENV_STUBS = {
    "R2_ACCOUNT_ID"        => "abc123",
    "R2_ACCESS_KEY_ID"     => "key",
    "R2_SECRET_ACCESS_KEY" => "secret",
    "R2_BUCKET"            => "test-bucket"
  }.freeze

  let(:config) do
    originals = ENV_STUBS.keys.to_h { |k| [ k, ENV[k] ] }
    ENV_STUBS.each { |k, v| ENV[k] = v }
    begin
      raw = ERB.new(File.read(Rails.root.join("config/storage.yml"))).result
      YAML.safe_load(raw, aliases: true).fetch("cloudflare_r2")
    ensure
      originals.each { |k, v| ENV[k] = v }
    end
  end

  it "uses the S3 service adapter (R2 is S3-compatible)" do
    expect(config["service"]).to eq("S3")
  end

  it "targets R2 with region 'auto' and a path-style endpoint" do
    expect(config["region"]).to eq("auto")
    expect(config["force_path_style"]).to eq(true)
    expect(config["endpoint"]).to eq("https://abc123.r2.cloudflarestorage.com")
  end

  it "serves blobs publicly" do
    expect(config["public"]).to eq(true)
  end

  describe "checksum compatibility" do
    # aws-sdk-s3 >= 1.119 emits x-amz-checksum-* headers by default.
    # R2 rejects them with Aws::S3::Errors::InvalidRequest.
    it "skips request checksums unless the server requires them" do
      expect(config["request_checksum_calculation"]).to eq("when_required")
    end

    it "skips response checksum validation unless the server requires it" do
      expect(config["response_checksum_validation"]).to eq("when_required")
    end
  end

  describe "Cache-Control on upload" do
    it "marks blobs immutable and cacheable for a year" do
      cache_control = config.dig("upload", "cache_control")
      expect(cache_control).to be_present
      expect(cache_control).to include("public")
      expect(cache_control).to include("immutable")
      expect(cache_control).to match(/max-age=\d+/)
    end
  end
end

RSpec.describe "Active Storage variant processor" do
  it "is pinned to :vips so dev and prod produce identical output" do
    expect(Rails.application.config.active_storage.variant_processor).to eq(:vips)
  end
end

RSpec.describe Article, "featured_image variants" do
  let(:variants) { Article.reflect_on_attachment(:featured_image).named_variants.keys }

  it "defines :thumb and :large" do
    expect(variants).to include(:thumb, :large)
  end

  it "does not define an unused :medium variant" do
    expect(variants).not_to include(:medium)
  end
end
