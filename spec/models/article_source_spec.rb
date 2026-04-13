require 'rails_helper'

RSpec.describe ArticleSource, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:article) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'accepts a blank url' do
      source = build(:article_source, url: nil)
      expect(source).to be_valid
    end

    it 'accepts a valid https url' do
      source = build(:article_source, url: "https://example.com/article")
      expect(source).to be_valid
    end

    it 'accepts a valid http url' do
      source = build(:article_source, url: "http://example.com/article")
      expect(source).to be_valid
    end

    it 'rejects a non-http url' do
      source = build(:article_source, url: "ftp://example.com/file")
      expect(source).not_to be_valid
      expect(source.errors[:url]).to be_present
    end

    it 'rejects a url without a scheme' do
      source = build(:article_source, url: "example.com/article")
      expect(source).not_to be_valid
      expect(source.errors[:url]).to be_present
    end
  end

  describe 'ordering' do
    it 'returns sources ordered by position then id' do
      article = create(:article)
      third  = create(:article_source, article: article, position: 2)
      first  = create(:article_source, article: article, position: 0)
      second = create(:article_source, article: article, position: 1)

      expect(article.sources.to_a).to eq([ first, second, third ])
    end
  end
end
