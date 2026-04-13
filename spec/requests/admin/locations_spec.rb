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
    it "returns success" do
      location = create(:location)
      get "/admin/locations/#{location.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/locations/:id" do
    let!(:location) { create(:location) }

    it "updates location" do
      patch "/admin/locations/#{location.id}", params: { location: { name: "Updated" } }
      expect(response).to redirect_to(admin_locations_path)
      expect(location.reload.name).to eq("Updated")
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
