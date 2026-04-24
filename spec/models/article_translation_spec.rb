require 'rails_helper'

RSpec.describe ArticleTranslation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:article) }
  end

  describe 'validations' do
    subject { build(:article_translation) }

    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:title) }

    it 'accepts supported locales' do
      ArticleTranslation.supported_locales.each do |locale|
        t = build(:article_translation, locale: locale)
        expect(t).to be_valid
      end
    end

    it 'rejects unsupported locales' do
      t = build(:article_translation, locale: "fr")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it 'rejects invalid slug formats' do
      t = build(:article_translation, slug: "Has Spaces!")
      expect(t).not_to be_valid
      expect(t.errors[:slug]).to be_present
    end

    it 'accepts valid slug formats' do
      t = build(:article_translation, slug: "valid-slug-123")
      expect(t).to be_valid
    end

    it 'enforces slug uniqueness per locale' do
      # Use a ja translation to avoid conflicting with the auto-created en one
      article = create(:article)
      create(:article_translation, article: article, locale: "ja", slug: "same-slug")
      duplicate = build(:article_translation, locale: "ja", slug: "same-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it 'allows the same slug in different locales' do
      article = create(:article)
      create(:article_translation, article: article, locale: "ja", slug: "shared-slug")
      other = build(:article_translation, locale: "en", slug: "shared-slug")
      expect(other).to be_valid
    end

    it 'enforces one translation per locale per article' do
      article = create(:article)
      # The article factory auto-creates an EN translation; a second one should be invalid
      duplicate = build(:article_translation, article: article, locale: "en", slug: "other-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to be_present
    end
  end

  describe 'slug auto-generation' do
    it 'generates slug from title when blank' do
      article = create(:article)
      t = create(:article_translation, article: article, locale: "ja",
                 title: "My Japanese Headline", slug: nil)
      expect(t.slug).to eq("my-japanese-headline")
    end

    it 'does not overwrite an explicitly provided slug' do
      article = create(:article)
      t = create(:article_translation, article: article, locale: "ja",
                 title: "Some Title", slug: "custom-slug")
      expect(t.slug).to eq("custom-slug")
    end
  end

  describe '#to_param' do
    it 'returns the slug' do
      t = build(:article_translation, slug: "my-slug")
      expect(t.to_param).to eq("my-slug")
    end
  end

  describe '.supported_locales' do
    it 'includes english and japanese by default' do
      expect(ArticleTranslation.supported_locales).to include("en", "ja")
    end
  end

  describe 'required vs optional locales' do
    it 'treats English as required' do
      expect(ArticleTranslation.required_locale?("en")).to be true
    end

    it 'treats Japanese as optional' do
      expect(ArticleTranslation.required_locale?("ja")).to be false
      expect(ArticleTranslation.optional_locales).to include("ja")
    end

    it 'accepts symbol or string input' do
      expect(ArticleTranslation.required_locale?(:en)).to be true
    end
  end
end
