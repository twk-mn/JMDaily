require 'rails_helper'

RSpec.describe SyncNewsletterAudienceJob, type: :job do
  let(:subscriber) { create(:newsletter_subscriber, :confirmed) }

  it "calls NewsletterAudience.subscribe for the subscribe action" do
    expect(NewsletterAudience).to receive(:subscribe).with(satisfy { |s| s.id == subscriber.id })
    described_class.perform_now(subscriber.id, "subscribe")
  end

  it "calls NewsletterAudience.unsubscribe for the unsubscribe action" do
    expect(NewsletterAudience).to receive(:unsubscribe).with(satisfy { |s| s.id == subscriber.id })
    described_class.perform_now(subscriber.id, "unsubscribe")
  end

  it "is a no-op for unknown actions" do
    expect(NewsletterAudience).not_to receive(:subscribe)
    expect(NewsletterAudience).not_to receive(:unsubscribe)
    described_class.perform_now(subscriber.id, "delete")
  end

  it "is a no-op when the subscriber no longer exists" do
    expect(NewsletterAudience).not_to receive(:subscribe)
    described_class.perform_now(0, "subscribe")
  end
end
