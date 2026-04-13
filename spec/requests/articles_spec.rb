require 'rails_helper'

RSpec.describe "Articles", type: :request do
  describe "GET /articles/:id" do
    it "returns success for published article" do
      article = create(:article, :published)
      get article_path(article)
      expect(response).to have_http_status(:success)
    end

    it "displays article content" do
      article = create(:article, :published, title: "Test Article Title", dek: "Test dek text")
      get article_path(article)
      expect(response.body).to include("Test Article Title")
      expect(response.body).to include("Test dek text")
    end

    it "returns 404 for draft articles" do
      article = create(:article, status: "draft")
      get "/articles/#{article.slug}"
      expect(response).to have_http_status(:not_found)
    end

    it "shows related articles" do
      category = create(:category)
      article = create(:article, :published, category: category)
      related = create(:article, :published, category: category, title: "Related Article")

      get article_path(article)
      expect(response.body).to include("Related Article")
    end
  end
end
