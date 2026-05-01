require 'rails_helper'

RSpec.describe "Locations", type: :request do
  describe "GET /locations/:slug" do
    it "returns success" do
      location = create(:location, name: "Joetsu", slug: "joetsu")
      get location_path(slug: location.slug)
      expect(response).to have_http_status(:success)
    end

    it "displays articles for that location" do
      location = create(:location, name: "Joetsu", slug: "joetsu")
      article = create(:article, :published, title: "Joetsu Article")
      create(:article_location, article: article, location: location)

      get location_path(slug: location.slug)
      expect(response.body).to include("Joetsu Article")
    end

    it "returns 404 for non-existent location" do
      get location_path(slug: "nonexistent")
      expect(response).to have_http_status(:not_found)
    end

    it "renders breadcrumbs with Home and the location name" do
      location = create(:location, name: "Joetsu", slug: "joetsu")
      get location_path(slug: location.slug)
      expect(response.body).to include('aria-label="Breadcrumb"')
      expect(response.body).to match(/aria-current="page"[^>]*>Joetsu</)
    end

    it "renders the empty state when the location has no articles" do
      location = create(:location, name: "Joetsu", slug: "joetsu")
      get location_path(slug: location.slug)
      expect(response.body).to include("No articles for this location yet")
    end

    describe "Open Graph meta" do
      it "uses the location description for meta_description when present" do
        create(:location, name: "Joetsu", slug: "joetsu", description: "Coverage of Joetsu City.")
        get location_path(slug: "joetsu")
        expect(response.body).to include('content="Coverage of Joetsu City."')
      end

      it "falls back to a generated description when location.description is blank" do
        create(:location, name: "Joetsu", slug: "joetsu", description: nil)
        get location_path(slug: "joetsu")
        expect(response.body).to include('content="News and coverage from Joetsu on Joetsu-Myoko Daily."')
      end

      it "uses the lead article's featured image as og:image when present" do
        location = create(:location, name: "Joetsu", slug: "joetsu")
        article = create(:article, :published, title: "Joetsu Snow")
        File.open(Rails.root.join("public/apple-touch-icon.png")) do |file|
          article.featured_image.attach(
            io: file,
            filename: "joetsu.png",
            content_type: "image/png"
          )
        end
        create(:article_location, article: article, location: location)

        get location_path(slug: location.slug)
        expect(response.body).to match(/property="og:image" content="[^"]+"/)
      end

      it "omits og:image when no articles have featured images" do
        location = create(:location, name: "Joetsu", slug: "joetsu")
        get location_path(slug: location.slug)
        expect(response.body).not_to include('property="og:image"')
      end
    end
  end
end
