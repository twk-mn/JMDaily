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

    describe "JSON-LD article type" do
      it "emits NewsArticle for default 'news' articles" do
        article = create(:article, :published, article_type: "news")
        get article_path(article)
        expect(response.body).to include('"@type":"NewsArticle"')
      end

      it "emits AnalysisNewsArticle for analysis pieces" do
        article = create(:article, :published, article_type: "analysis")
        get article_path(article)
        expect(response.body).to include('"@type":"AnalysisNewsArticle"')
      end

      it "emits BackgroundNewsArticle for explainers" do
        article = create(:article, :published, article_type: "explainer")
        get article_path(article)
        expect(response.body).to include('"@type":"BackgroundNewsArticle"')
      end
    end

    describe "JSON-LD discovery fields" do
      it "emits articleSection from the article's category name" do
        category = create(:category, name: "Politics")
        article = create(:article, :published, category: category)
        get article_path(article)
        expect(response.body).to include('"articleSection":"Politics"')
      end

      it "emits inLanguage matching the served translation locale" do
        article = create(:article, :published)
        get article_path(article)
        expect(response.body).to include('"inLanguage":"en"')
      end

      it "emits keywords as an array of tag names when tags are present" do
        article = create(:article, :published)
        article.tags << create(:tag, name: "Niigata")
        article.tags << create(:tag, name: "Mayor")
        get article_path(article)
        expect(response.body).to include('"keywords":["Niigata","Mayor"]')
      end

      it "omits keywords entirely when the article has no tags" do
        article = create(:article, :published)
        get article_path(article)
        expect(response.body).not_to include('"keywords"')
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

      it "renders Twitter and Website links when set on the author" do
        author = create(:author, bio: "Bio.",
                                 twitter_url: "https://twitter.com/jane",
                                 website_url: "https://jane.example")
        article = create(:article, :published, author: author)

        get article_path(article)

        expect(response.body).to include('href="https://twitter.com/jane"')
        expect(response.body).to include('>Twitter</a>')
        expect(response.body).to include('href="https://jane.example"')
        expect(response.body).to include('>Website</a>')
      end

      it "drops non-http(s) author URLs" do
        author = create(:author, bio: "Bio.",
                                 twitter_url: "javascript:alert(1)",
                                 website_url: nil)
        article = create(:article, :published, author: author)

        get article_path(article)

        expect(response.body).not_to include("javascript:alert")
        expect(response.body).not_to include(">Twitter</a>")
      end
    end

    describe "corrections" do
      it "omits the corrections section when there are none" do
        article = create(:article, :published)
        get article_path(article)
        expect(response.body).not_to include('aria-label="Corrections"')
      end

      it "renders corrections in chronological order with timestamps" do
        article = create(:article, :published)
        create(:correction, article: article,
               body: "Misnamed the venue. The event was at City Hall, not the library.",
               posted_at: Time.zone.local(2026, 4, 20, 9, 0))
        create(:correction, article: article,
               body: "Updated the attendance figure from 200 to 220.",
               posted_at: Time.zone.local(2026, 4, 22, 14, 30))

        get article_path(article)

        expect(response.body).to include('aria-label="Corrections"')
        expect(response.body).to include("2 Corrections")
        # Earlier correction comes first.
        venue_idx      = response.body.index("City Hall")
        attendance_idx = response.body.index("attendance figure")
        expect(venue_idx).to be < attendance_idx
        expect(response.body).to match(/<time datetime="2026-04-20/)
      end
    end
  end
end
