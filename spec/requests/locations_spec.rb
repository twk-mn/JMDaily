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

    describe "translated name and description" do
      it "renders the JA name in the heading and breadcrumb when a JA translation exists" do
        location = create(:location, name: "Joetsu", slug: "joetsu", description: "Coverage of Joetsu.")
        location.translations.create!(locale: "ja", name: "上越", description: "上越市の取材")

        get "/ja/locations/joetsu"
        expect(response.body).to include("上越")
        expect(response.body).to include("上越市の取材")
      end

      it "falls back to English when no translation exists for the active locale" do
        create(:location, name: "Joetsu", slug: "joetsu", description: "Coverage of Joetsu.")

        get "/ja/locations/joetsu"
        expect(response.body).to include("Joetsu")
        expect(response.body).to include("Coverage of Joetsu.")
      end
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

    describe "CollectionPage JSON-LD" do
      it "emits a CollectionPage with the location name and description" do
        location = create(:location, name: "Joetsu", slug: "joetsu", description: "Coverage of Joetsu City.")
        get location_path(slug: location.slug)
        expect(response.body).to include('"@type":"CollectionPage"')
        expect(response.body).to include('"name":"Joetsu"')
        expect(response.body).to include('"description":"Coverage of Joetsu City."')
      end

      it "lists location articles in the ItemList" do
        location = create(:location, name: "Joetsu", slug: "joetsu")
        article = create(:article, :published, title: "Joetsu Article")
        create(:article_location, article: article, location: location)

        get location_path(slug: location.slug)
        expect(response.body).to include('"@type":"ItemList"')
        expect(response.body).to include('"name":"Joetsu Article"')
      end
    end
  end
end
