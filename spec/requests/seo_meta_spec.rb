require 'rails_helper'

RSpec.describe "SEO meta", type: :request do
  describe "sitewide JSON-LD" do
    it "emits Organization + WebSite structured data on the homepage" do
      get "/en"
      expect(response.body).to include('"@type":"Organization"')
      expect(response.body).to include('"@type":"WebSite"')
      expect(response.body).to include('"@type":"SearchAction"')
      expect(response.body).to include("/en/search?q={search_term_string}")
    end

    it "emits sitewide JSON-LD on category pages too" do
      create(:category, slug: "news", name: "News")
      get "/en/news"
      expect(response.body).to include('"@type":"Organization"')
      expect(response.body).to include('"@type":"WebSite"')
    end
  end

  describe "canonical URL" do
    it "renders a canonical link for the current path on the homepage" do
      get "/en"
      expect(response.body).to match(%r{<link rel="canonical" href="https?://[^"]+/en">})
    end

    it "uses the per-page canonical override when set (article)" do
      article = create(:article, :published, canonical_url: "https://other.example.com/source-article")
      get article_path(article)
      expect(response.body).to include('<link rel="canonical" href="https://other.example.com/source-article">')
    end
  end

  describe "hreflang alternates" do
    it "emits hreflang links for every active locale on category pages" do
      create(:category, slug: "news", name: "News")
      get "/en/news"
      SiteLanguage.active_codes.each do |code|
        expect(response.body).to match(/<link rel="alternate" hreflang="#{code}" href="[^"]+\/#{code}\/news">/)
      end
    end

    it "uses per-translation slugs for article hreflang (not path substitution)" do
      article = create(:article, :published)
      # The English translation already exists via the factory; add a Japanese one.
      article.translations.create!(locale: "ja", title: "日本語タイトル", slug: "ja-slug", dek: "")
      get article_path(article)
      expect(response.body).to match(%r{<link rel="alternate" hreflang="ja" href="[^"]+/ja/articles/ja-slug">})
    end
  end

  describe "robots meta" do
    it "marks the search results page as noindex,follow" do
      get "/en/search"
      expect(response.body).to include('<meta name="robots" content="noindex,follow">')
    end

    it "does not emit a robots meta on regular content pages" do
      get "/en"
      expect(response.body).not_to include('<meta name="robots"')
    end
  end
end
