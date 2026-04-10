require 'rails_helper'

RSpec.describe "Admin::StaticPages", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/static_pages" do
    it "returns success" do
      get admin_static_pages_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/static_pages/new" do
    it "returns success" do
      get new_admin_static_page_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/static_pages" do
    it "creates page" do
      expect {
        post admin_static_pages_path, params: {
          static_page: { title: "FAQ", slug: "faq" }
        }
      }.to change(StaticPage, :count).by(1)
      expect(response).to redirect_to(admin_static_pages_path)
    end

    it "re-renders with invalid params" do
      post admin_static_pages_path, params: { static_page: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/static_pages/:id/edit" do
    it "returns success" do
      page = create(:static_page)
      get "/admin/static_pages/#{page.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/static_pages/:id" do
    let!(:page) { create(:static_page) }

    it "updates page" do
      patch "/admin/static_pages/#{page.id}", params: {
        static_page: { title: "Updated Title" }
      }
      expect(response).to redirect_to(admin_static_pages_path)
      expect(page.reload.title).to eq("Updated Title")
    end
  end

  describe "DELETE /admin/static_pages/:id" do
    it "destroys page" do
      page = create(:static_page)
      expect {
        delete "/admin/static_pages/#{page.id}"
      }.to change(StaticPage, :count).by(-1)
    end
  end
end
