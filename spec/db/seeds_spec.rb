require "rails_helper"

# Exercises db/seeds.rb end-to-end so the dev seed flow doesn't silently
# rot. Runs the file in a clean state and asserts the expected fixtures
# show up: multiple authors with social links, articles in EN+JA across
# categories, a correction, mixed-status comments, and at least one ad.
RSpec.describe "db/seeds.rb", type: :model do
  # Run the seed in each example's transaction so transactional_fixtures
  # rolls back the inserted rows after assertions run. before(:all) would
  # leak the seed data into every other spec in the suite.
  before do
    silence_stream($stdout) { load Rails.root.join("db/seeds.rb") }
  end

  it "creates multiple editorial authors with social links" do
    expect(Author.count).to be >= 4
    aya = Author.find_by(slug: "aya-tanaka")
    expect(aya).to be_present
    expect(aya.twitter_url).to be_present
    expect(aya.bluesky_url).to be_present
  end

  it "creates sample articles across multiple categories with EN+JA translations" do
    articles = Article.published
    expect(articles.count).to eq(7)

    articles.each do |article|
      locales = article.translations.pluck(:locale).sort
      expect(locales).to eq(%w[en ja]), "expected EN + JA for #{article.slug}, got #{locales.inspect}"
    end

    category_slugs = articles.map { |a| a.category.slug }.uniq.sort
    expect(category_slugs).to include("politics", "weather-travel", "business", "community", "events", "opinion")
  end

  it "flags at least one article as breaking and one as featured" do
    expect(Article.breaking.count).to be >= 1
    expect(Article.featured.count).to be >= 1
  end

  it "links articles to tags and locations" do
    expect(ArticleTag.count).to be >= 5
    expect(ArticleLocation.count).to be >= 5
  end

  it "creates a correction so the corrections aside renders" do
    expect(Correction.count).to be >= 1
  end

  it "creates approved + pending comments so admin moderation has data" do
    expect(Comment.where(status: "approved").count).to be >= 2
    expect(Comment.where(status: "pending").count).to be >= 1
  end

  it "creates at least one ad" do
    expect(Ad.count).to be >= 1
    expect(Ad.where(placement_zone: "homepage_mid").count).to be >= 1
  end

  it "is idempotent — re-running the seed does not duplicate sample articles" do
    # The before block already loaded the seed once; loading it again in the
    # same transaction should short-circuit on the Article.exists? guard.
    expect {
      silence_stream($stdout) { load Rails.root.join("db/seeds.rb") }
    }.not_to change(Article, :count)
  end

  private

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(File::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end
