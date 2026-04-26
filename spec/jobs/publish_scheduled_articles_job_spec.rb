require 'rails_helper'

RSpec.describe PublishScheduledArticlesJob, type: :job do
  it "publishes articles whose published_at is in the past" do
    article = create(:article, :scheduled, published_at: 5.minutes.ago)

    described_class.perform_now

    expect(article.reload.status).to eq("published")
  end

  it "leaves future-scheduled articles alone" do
    article = create(:article, :scheduled, published_at: 1.hour.from_now)

    described_class.perform_now

    expect(article.reload.status).to eq("scheduled")
  end

  it "enqueues a sitemap regeneration when articles are published" do
    create(:article, :scheduled, published_at: 5.minutes.ago)

    expect { described_class.perform_now }.to have_enqueued_job(RegenerateSitemapJob)
  end

  it "does not enqueue a sitemap regeneration when no articles are due" do
    expect { described_class.perform_now }.not_to have_enqueued_job(RegenerateSitemapJob)
  end
end
