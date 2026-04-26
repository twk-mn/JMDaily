require 'rails_helper'

RSpec.describe Turnstile do
  after { described_class.test_verification_result = nil }

  describe ".configured?" do
    it "is false when either key is blank" do
      Setting.set("turnstile_site_key", "site")
      Setting.set("turnstile_secret_key", "")
      expect(described_class).not_to be_configured
    end

    it "is true when both keys are set" do
      Setting.set("turnstile_site_key", "site")
      Setting.set("turnstile_secret_key", "secret")
      expect(described_class).to be_configured
    end
  end

  describe ".enabled_for?" do
    before do
      Setting.set("turnstile_site_key", "site")
      Setting.set("turnstile_secret_key", "secret")
      Setting.set("turnstile_on_comments", true)
    end

    it "is false for unknown form keys" do
      expect(described_class.enabled_for?("unknown")).to eq(false)
    end

    it "is false when keys are not configured even if the toggle is on" do
      Setting.set("turnstile_secret_key", "")
      expect(described_class.enabled_for?("comments")).to eq(false)
    end

    it "is false when the per-form toggle is off" do
      Setting.set("turnstile_on_comments", false)
      expect(described_class.enabled_for?("comments")).to eq(false)
    end

    it "is true when keys are configured and the toggle is on" do
      expect(described_class.enabled_for?("comments")).to eq(true)
    end

    it "accepts symbol form keys" do
      expect(described_class.enabled_for?(:comments)).to eq(true)
    end
  end

  describe ".verify" do
    it "returns the test override in test env without making HTTP calls" do
      described_class.test_verification_result = true
      expect(Net::HTTP).not_to receive(:new)
      expect(described_class.verify("any-token")).to eq(true)
    end

    it "returns false for the failure override" do
      described_class.test_verification_result = false
      expect(described_class.verify("any-token")).to eq(false)
    end
  end
end
