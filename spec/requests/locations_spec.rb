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
