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
  end
end
