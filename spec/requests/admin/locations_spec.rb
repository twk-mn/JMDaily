require 'rails_helper'

RSpec.describe "Admin::Locations", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/locations" do
    it "returns success" do
      get admin_locations_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/locations/new" do
    it "returns success" do
      get new_admin_location_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/locations" do
    it "creates location" do
      expect {
        post admin_locations_path, params: { location: { name: "Itoigawa" } }
      }.to change(Location, :count).by(1)
      expect(response).to redirect_to(admin_locations_path)
    end

    it "re-renders with invalid params" do
      post admin_locations_path, params: { location: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/locations/:id/edit" do
    it "returns success when accessed by integer id" do
      location = create(:location)
      get "/admin/locations/#{location.id}/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns success when accessed by slug (since Location#to_param returns slug)" do
      create(:location, name: "Joetsu", slug: "joetsu")
      get "/admin/locations/joetsu/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns 404 for an unknown slug" do
      get "/admin/locations/does-not-exist/edit"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/locations/:id" do
    let!(:location) { create(:location) }

    it "updates location" do
      patch "/admin/locations/#{location.id}", params: { location: { name: "Updated" } }
      expect(response).to redirect_to(admin_locations_path)
      expect(location.reload.name).to eq("Updated")
    end

    it "creates a translation through nested attributes" do
      patch "/admin/locations/#{location.id}", params: {
        location: {
          translations_attributes: [
            { locale: "ja", name: "上越", description: "上越市の取材" }
          ]
        }
      }
      expect(response).to redirect_to(admin_locations_path)
      expect(location.reload.translation_for(:ja)&.name).to eq("上越")
    end

    it "drops a translation row when every translatable field is left blank" do
      # Edit form pre-builds a JA translation row even when no JA copy is
      # provided. Submitting with everything blank shouldn't create an
      # empty translation in the DB.
      expect {
        patch "/admin/locations/#{location.id}", params: {
          location: {
            translations_attributes: [
              { locale: "ja", name: "", description: "" }
            ]
          }
        }
      }.not_to change(LocationTranslation, :count)
    end
  end

  describe "GET /admin/locations/:id/edit form" do
    it "pre-builds a translation section per active non-English language" do
      location = create(:location, name: "Joetsu", slug: "joetsu")
      get edit_admin_location_path(location)
      # The hidden locale input identifies the JA section the form rendered.
      expect(response.body).to include('name="location[translations_attributes][0][locale]"')
      expect(response.body).to include('value="ja"')
    end
  end

  describe "DELETE /admin/locations/:id" do
    it "destroys location" do
      location = create(:location)
      expect {
        delete "/admin/locations/#{location.id}"
      }.to change(Location, :count).by(-1)
    end
  end
end
