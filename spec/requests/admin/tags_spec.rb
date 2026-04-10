require 'rails_helper'

RSpec.describe "Admin::Tags", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/tags" do
    it "returns success" do
      get admin_tags_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/tags/new" do
    it "returns success" do
      get new_admin_tag_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/tags" do
    it "creates tag" do
      expect {
        post admin_tags_path, params: { tag: { name: "Winter" } }
      }.to change(Tag, :count).by(1)
      expect(response).to redirect_to(admin_tags_path)
    end

    it "re-renders with invalid params" do
      post admin_tags_path, params: { tag: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/tags/:id/edit" do
    it "returns success" do
      tag = create(:tag)
      get "/admin/tags/#{tag.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/tags/:id" do
    let!(:tag) { create(:tag) }

    it "updates tag" do
      patch "/admin/tags/#{tag.id}", params: { tag: { name: "Updated" } }
      expect(response).to redirect_to(admin_tags_path)
      expect(tag.reload.name).to eq("Updated")
    end
  end

  describe "DELETE /admin/tags/:id" do
    it "destroys tag" do
      tag = create(:tag)
      expect {
        delete "/admin/tags/#{tag.id}"
      }.to change(Tag, :count).by(-1)
    end
  end
end
