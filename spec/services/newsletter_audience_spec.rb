require 'rails_helper'

RSpec.describe NewsletterAudience do
  after { described_class.test_sync_result = nil }

  describe ".configured?" do
    it "is false by default" do
      expect(described_class).not_to be_configured
    end

    it "is false when provider is set but the API key or audience ID is blank" do
      Setting.set("newsletter_provider", "resend")
      Setting.set("newsletter_audience_id", "aud_123")
      expect(described_class).not_to be_configured

      Setting.set("newsletter_api_key", "re_abc")
      Setting.set("newsletter_audience_id", "")
      expect(described_class).not_to be_configured
    end

    it "is true when provider, api key, and audience id are all set" do
      Setting.set("newsletter_provider", "resend")
      Setting.set("newsletter_api_key", "re_abc")
      Setting.set("newsletter_audience_id", "aud_123")
      expect(described_class).to be_configured
    end

    it "treats an unknown provider value as 'none'" do
      Setting.set("newsletter_provider", "constant_contact")
      Setting.set("newsletter_api_key", "k")
      Setting.set("newsletter_audience_id", "a")
      expect(described_class.provider).to eq("none")
      expect(described_class).not_to be_configured
    end
  end

  describe ".subscribe / .unsubscribe" do
    before do
      Setting.set("newsletter_provider", "resend")
      Setting.set("newsletter_api_key", "re_abc")
      Setting.set("newsletter_audience_id", "aud_123")
    end

    it "returns false (and makes no HTTP call) when not configured" do
      Setting.set("newsletter_provider", "none")
      subscriber = build_stubbed(:newsletter_subscriber)
      expect(Net::HTTP).not_to receive(:new)
      expect(described_class.subscribe(subscriber)).to eq(false)
      expect(described_class.unsubscribe(subscriber)).to eq(false)
    end

    it "honours the test override without making HTTP calls" do
      described_class.test_sync_result = true
      subscriber = build_stubbed(:newsletter_subscriber)
      expect(Net::HTTP).not_to receive(:new)
      expect(described_class.subscribe(subscriber)).to eq(true)
      expect(described_class.unsubscribe(subscriber)).to eq(true)
    end

    it "returns the failure override too" do
      described_class.test_sync_result = false
      subscriber = build_stubbed(:newsletter_subscriber)
      expect(described_class.subscribe(subscriber)).to eq(false)
    end
  end
end
