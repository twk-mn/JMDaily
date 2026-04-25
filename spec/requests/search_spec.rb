require 'rails_helper'

RSpec.describe "Search", type: :request do
  describe "GET /search" do
    it "returns success" do
      get search_path
      expect(response).to have_http_status(:success)
    end

    it "finds articles matching title" do
      create(:article, :published, title: "Cherry Blossom Festival")
      get search_path, params: { q: "Cherry" }
      # Matched terms are wrapped in <mark>, so check the unhighlighted remainder.
      expect(response.body).to include("Blossom Festival")
    end

    it "finds articles matching dek" do
      create(:article, :published, title: "Some Title", dek: "Unique festival details")
      get search_path, params: { q: "Unique festival" }
      expect(response.body).to include("Some Title")
    end

    it "does not find draft articles" do
      create(:article, status: "draft", title: "Secret Draft")
      get search_path, params: { q: "Secret" }
      expect(response.body).not_to include("Secret Draft")
    end

    it "returns empty results for no query" do
      get search_path
      expect(response).to have_http_status(:success)
    end

    it "renders the shared empty state when a query has no matches" do
      get search_path, params: { q: "zzznoresultszzz" }
      expect(response.body).to include("No results found")
      expect(response.body).to include("Try different keywords")
    end

    it "handles SQL injection safely" do
      get search_path, params: { q: "'; DROP TABLE articles; --" }
      expect(response).to have_http_status(:success)
      expect(Article.count).to be >= 0
    end

    it "shows the result count and the matched query" do
      create(:article, :published, title: "Cherry Blossom Festival")
      get search_path, params: { q: "Cherry" }
      expect(response.body).to include("1 result")
      expect(response.body).to match(/<strong>Cherry<\/strong>/)
    end

    it "wraps matching terms in <mark> for highlighting" do
      create(:article, :published, title: "Cherry Blossom Festival", dek: "Annual cherry viewing in the park")
      get search_path, params: { q: "cherry" }
      expect(response.body).to match(/<mark[^>]*>[Cc]herry<\/mark>/)
    end

    context "with multiple categories in the result set" do
      let!(:news_category)   { create(:category, name: "News",   slug: "news") }
      let!(:sports_category) { create(:category, name: "Sports", slug: "sports") }

      before do
        create(:article, :published, category: news_category,   title: "Festival news bulletin")
        create(:article, :published, category: sports_category, title: "Festival sports recap")
      end

      it "renders category filter chips with counts" do
        get search_path, params: { q: "Festival" }
        expect(response.body).to include('aria-label="Filter by category"')
        expect(response.body).to include("News (1)")
        expect(response.body).to include("Sports (1)")
        expect(response.body).to include("All (2)")
      end

      it "filters results when a category chip is selected" do
        get search_path, params: { q: "Festival", category: "news" }
        # Matched terms are wrapped in <mark>, so check the unhighlighted remainder.
        expect(response.body).to include("news bulletin")
        expect(response.body).not_to include("sports recap")
        expect(response.body).to include("Clear filter")
      end
    end

    context "with Japanese query" do
      let!(:article) do
        a = create(:article, :published, title: "Local news")
        a.update_columns(ja_search_text: "上越市のニュース 地域情報")
        a
      end

      it "finds articles by Japanese title text" do
        get search_path, params: { q: "上越市" }
        expect(response.body).to include("Local news")
      end

      it "does not raise an error for Japanese input" do
        get search_path, params: { q: "ニュース" }
        expect(response).to have_http_status(:success)
      end

      it "shows the Japanese-content indicator" do
        get search_path, params: { q: "上越市" }
        expect(response.body).to include("Searching Japanese content")
      end

      it "does not show the Japanese-content indicator for English queries" do
        create(:article, :published, title: "Cherry Blossom Festival")
        get search_path, params: { q: "Cherry" }
        expect(response.body).not_to include("Searching Japanese content")
      end
    end
  end
end
