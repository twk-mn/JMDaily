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
  end
end
