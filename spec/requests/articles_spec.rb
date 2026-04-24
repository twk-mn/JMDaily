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
      get article_path(article)
      expect(response).to have_http_status(:not_found)
    end

    it "shows related articles" do
      category = create(:category)
      article = create(:article, :published, category: category)
      related = create(:article, :published, category: category, title: "Related Article")

      get article_path(article)
      expect(response.body).to include("Related Article")
    end

    describe "breadcrumbs" do
      it "renders a Breadcrumb nav with category and article" do
        category = create(:category, name: "Business", slug: "business")
        article = create(:article, :published, category: category, title: "Trade deal announced")

        get article_path(article)

        expect(response.body).to include('aria-label="Breadcrumb"')
        expect(response.body).to include("Business")
        expect(response.body).to match(/aria-current="page"[^>]*>[\s\S]*?Trade deal announced/)
      end

      it "emits BreadcrumbList JSON-LD" do
        article = create(:article, :published)
        get article_path(article)

        expect(response.body).to include('"@type":"BreadcrumbList"')
        expect(response.body).to include('"position":1')
      end
    end

    describe "author bio" do
      it "renders an author bio card when the author has a bio" do
        author = create(:author, name: "Jane Doe", bio: "Jane has covered Niigata for a decade.")
        article = create(:article, :published, author: author)

        get article_path(article)

        expect(response.body).to include("About the author")
        expect(response.body).to include("Jane has covered Niigata for a decade.")
      end

      it "omits the author bio card when the author has no bio, photo, or role" do
        author = create(:author, name: "Anonymous", bio: nil, role_title: nil)
        article = create(:article, :published, author: author)

        get article_path(article)

        expect(response.body).not_to include("About the author")
      end
    end
  end
end
