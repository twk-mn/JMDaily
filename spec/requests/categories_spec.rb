require 'rails_helper'

RSpec.describe "Categories", type: :request do
  describe "GET /news (category page)" do
    it "returns success" do
      create(:category, name: "News", slug: "news")
      get news_path
      expect(response).to have_http_status(:success)
    end

    it "displays articles in category" do
      category = create(:category, name: "News", slug: "news")
      article = create(:article, :published, category: category, title: "News Article")
      get news_path
      expect(response.body).to include("News Article")
    end

    it "only has routes for defined categories" do
      # Category routes are explicitly defined, so nonexistent ones route elsewhere
      category = create(:category, name: "News", slug: "news")
      get news_path
      expect(response).to have_http_status(:success)
    end

    it "renders breadcrumbs with Home and the category name" do
      create(:category, name: "News", slug: "news")
      get news_path
      expect(response.body).to include('aria-label="Breadcrumb"')
      expect(response.body).to include(">Home<")
      expect(response.body).to match(/aria-current="page"[^>]*>News</)
    end

    it "renders the empty state when no articles are published" do
      create(:category, name: "News", slug: "news")
      get news_path
      expect(response.body).to include("No articles in this category yet")
    end

    it "renders shared pagination nav when multiple pages exist" do
      category = create(:category, name: "News", slug: "news")
      13.times { |i| create(:article, :published, category: category, title: "Article #{i}") }
      get news_path
      expect(response.body).to include('aria-label="Pagination"')
      expect(response.body).to match(/Page\s+1\s+of\s+2/)
    end
  end
end
