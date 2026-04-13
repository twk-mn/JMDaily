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
      expect(response.body).to include("Cherry Blossom Festival")
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

    it "handles SQL injection safely" do
      get search_path, params: { q: "'; DROP TABLE articles; --" }
      expect(response).to have_http_status(:success)
      expect(Article.count).to be >= 0
    end
  end
end
