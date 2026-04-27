require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /en" do
    it "returns success" do
      get locale_root_path
      expect(response).to have_http_status(:success)
    end

    it "displays lead story when featured article exists" do
      article = create(:article, :featured)
      get locale_root_path
      expect(response.body).to include(article.title)
    end

    it "displays latest articles" do
      articles = create_list(:article, 3, :published)
      get locale_root_path
      articles.each do |article|
        expect(response.body).to include(article.title)
      end
    end

    it "displays breaking news" do
      create(:article, :breaking, title: "Breaking News Story")
      get locale_root_path
      expect(response.body).to include("Breaking News Story")
    end

    it "displays location-based articles" do
      joetsu = create(:location, name: "Joetsu", slug: "joetsu")
      article = create(:article, :published, title: "Joetsu Story")
      create(:article_location, article: article, location: joetsu)

      get locale_root_path
      expect(response.body).to include("Joetsu Story")
    end

    describe "section layout" do
      it "renders the hero with up to three stacked secondary stories" do
        create(:article, :featured, title: "Lead Story")
        create_list(:article, 4, :published).each_with_index do |a, i|
          a.translations.first.update!(title: "Recent Story #{i}")
          a.update!(title: "Recent Story #{i}")
        end

        get locale_root_path
        expect(response.body).to include("Lead Story")
        expect(response.body).to include('aria-label="Top stories"')
      end

      it "renders a Local News grid from the News category" do
        news = create(:category, name: "News", slug: "news")
        # Hero + 3 secondaries consume the four most recent articles, so the
        # fifth one lands in the Local News grid.
        5.times { |i| create(:article, :published, category: news, title: "News Item #{i}", published_at: (i + 1).hours.ago) }
        get locale_root_path
        expect(response.body).to include("News Item 4")
        expect(response.body).to match(/>Local News</)
      end

      it "renders the newsletter capture card with a subscribe form" do
        get locale_root_path
        expect(response.body).to include("Get the Joetsu-Myoko Daily")
        expect(response.body).to include(%(action="#{newsletter_subscribe_path}))
        expect(response.body).to include('id="home-newsletter-email"')
      end

      it "honors SiteConfig::HOMEPAGE_SECTIONS ordering" do
        original = SiteConfig::HOMEPAGE_SECTIONS
        stub_const("SiteConfig::HOMEPAGE_SECTIONS", %i[newsletter ad_mid])

        get locale_root_path

        expect(response.body).to include("Get the Joetsu-Myoko Daily")
        # Only these two sections are rendered now — hero / local_news / locations
        # should be absent.
        expect(response.body).not_to include('aria-label="Top stories"')
      ensure
        stub_const("SiteConfig::HOMEPAGE_SECTIONS", original) if original
      end
    end

    describe "language switcher" do
      it "renders a link for every active SiteLanguage" do
        SiteLanguage.create!(code: "ko", position: 5, active: true)

        get locale_root_path
        expect(response.body).to include('href="/ko"')
        expect(response.body).to include('href="/en"')
        expect(response.body).to include('href="/ja"')
      end

      it "omits languages that are inactive" do
        SiteLanguage.find_by(code: "ja").update!(active: false)

        get locale_root_path
        expect(response.body).not_to include('href="/ja"')
      end

      it "marks the current locale with aria-current" do
        get locale_root_path(locale: "en")
        # Scope to the language-switcher pill group so we don't match the
        # masthead's locale_root_path link, which also points at /en.
        switcher = response.body[/<div[^>]*aria-label="Language"[^>]*>.*?<\/div>/m]
        en_link = switcher[/<a\b[^>]*href="\/en"[^>]*>/] || switcher[/<a\b[^>]*aria-current[^>]*href="\/en"[^>]*>/]
        expect(en_link).to include('aria-current="true"')
      end
    end
  end
end
