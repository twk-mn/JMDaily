require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays lead story when featured article exists" do
      article = create(:article, :featured)
      get root_path
      expect(response.body).to include(article.title)
    end

    it "displays latest articles" do
      articles = create_list(:article, 3, :published)
      get root_path
      articles.each do |article|
        expect(response.body).to include(article.title)
      end
    end

    it "displays breaking news" do
      breaking = create(:article, :breaking, title: "Breaking News Story")
      get root_path
      expect(response.body).to include("Breaking News Story")
    end

    it "displays location-based articles" do
      joetsu = create(:location, name: "Joetsu", slug: "joetsu")
      article = create(:article, :published, title: "Joetsu Story")
      create(:article_location, article: article, location: joetsu)

      get root_path
      expect(response.body).to include("Joetsu Story")
    end
  end
end
