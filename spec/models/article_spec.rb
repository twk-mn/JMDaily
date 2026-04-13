require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:translations).dependent(:destroy) }
    it { is_expected.to have_many(:sources).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:article_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:article_tags) }
    it { is_expected.to have_many(:article_locations).dependent(:destroy) }
    it { is_expected.to have_many(:locations).through(:article_locations) }
  end

  describe 'validations' do
    subject { build(:article) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or title to auto-generate)' do
      article = build(:article, title: nil, slug: nil)
      expect(article).not_to be_valid
    end
    it { is_expected.to validate_inclusion_of(:status).in_array(Article::STATUSES) }

    it 'requires published_at when status is published' do
      article = build(:article, status: "published", published_at: nil)
      expect(article).not_to be_valid
      expect(article.errors[:published_at]).to be_present
    end

    it 'does not require published_at for drafts' do
      article = build(:article, status: "draft", published_at: nil)
      expect(article).to be_valid
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from title' do
      article = create(:article, title: "My Great Article", slug: nil)
      expect(article.slug).to eq("my-great-article")
    end
  end

  describe 'slug format validation' do
    it 'rejects invalid slugs' do
      article = build(:article, slug: "Invalid Slug!")
      expect(article).not_to be_valid
    end

    it 'accepts valid slugs' do
      article = build(:article, slug: "valid-slug-123")
      expect(article).to be_valid
    end
  end

  describe 'scopes' do
    let!(:published) { create(:article, :published) }
    let!(:draft) { create(:article, status: "draft") }
    let!(:featured) { create(:article, :featured) }
    let!(:breaking) { create(:article, :breaking) }

    describe '.published' do
      it 'returns only published articles with past published_at' do
        results = Article.published
        expect(results).to include(published, featured, breaking)
        expect(results).not_to include(draft)
      end
    end

    describe '.draft' do
      it 'returns only draft articles' do
        expect(Article.draft).to include(draft)
        expect(Article.draft).not_to include(published)
      end
    end

    describe '.featured' do
      it 'returns only featured articles' do
        expect(Article.featured).to include(featured)
        expect(Article.featured).not_to include(published)
      end
    end

    describe '.breaking' do
      it 'returns only breaking articles' do
        expect(Article.breaking).to include(breaking)
        expect(Article.breaking).not_to include(published)
      end
    end

    describe '.recent' do
      it 'returns published articles ordered by published_at desc' do
        results = Article.recent
        expect(results).to include(published)
        expect(results).not_to include(draft)
      end
    end

    describe '.by_category' do
      it 'returns articles for a specific category' do
        results = Article.by_category(published.category)
        expect(results).to include(published)
      end
    end

    describe '.by_location' do
      it 'returns articles for a specific location' do
        location = create(:location)
        create(:article_location, article: published, location: location)
        results = Article.by_location(location)
        expect(results).to include(published)
        expect(results).not_to include(draft)
      end
    end
  end

  describe '#published?' do
    it 'returns true when status is published and published_at is in the past' do
      article = build(:article, status: "published", published_at: 1.hour.ago)
      expect(article).to be_published
    end

    it 'returns false for drafts' do
      article = build(:article, status: "draft")
      expect(article).not_to be_published
    end

    it 'returns false when published_at is in the future' do
      article = build(:article, status: "published", published_at: 1.day.from_now)
      expect(article).not_to be_published
    end
  end

  describe '#display_date' do
    it 'returns published_at when available' do
      time = 2.hours.ago.change(usec: 0)
      article = build(:article, published_at: time)
      expect(article.display_date).to eq(time)
    end

    it 'returns created_at when published_at is nil' do
      article = create(:article, published_at: nil)
      expect(article.display_date).to eq(article.created_at)
    end
  end

  describe '#effective_seo_title' do
    it 'returns article seo_title when present' do
      article = build(:article, seo_title: "SEO Title")
      expect(article.effective_seo_title).to eq("SEO Title")
    end

    it 'falls back to translation title' do
      article = build(:article, seo_title: nil, title: "Fallback")
      translation = build(:article_translation, title: "Translation Title", seo_title: nil)
      expect(article.effective_seo_title(translation)).to eq("Translation Title")
    end
  end

  describe '#effective_meta_description' do
    it 'returns meta_description when present' do
      article = build(:article, meta_description: "Meta desc")
      expect(article.effective_meta_description).to eq("Meta desc")
    end

    it 'falls back to translation dek' do
      article = build(:article, meta_description: nil, dek: nil)
      translation = build(:article_translation, dek: "Translation dek", meta_description: nil)
      expect(article.effective_meta_description(translation)).to eq("Translation dek")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      article = build(:article, slug: "test-article")
      expect(article.to_param).to eq("test-article")
    end
  end

  describe '#reading_time' do
    it 'returns at least 1 minute when no translation body' do
      article = create(:article)
      expect(article.reading_time(nil)).to be >= 1
    end

    it 'increases with more words' do
      short_translation = build(:article_translation)
      long_translation  = build(:article_translation)
      allow(short_translation.body).to receive(:to_plain_text).and_return("word " * 100)
      allow(long_translation.body).to receive(:to_plain_text).and_return("word " * 400)

      article = create(:article)
      expect(article.reading_time(long_translation)).to be > article.reading_time(short_translation)
    end
  end
end
