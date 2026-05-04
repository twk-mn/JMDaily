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
    it "returns success when accessed by integer id" do
      page = create(:static_page)
      get "/admin/static_pages/#{page.id}/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns success when accessed by slug (since StaticPage#to_param returns slug)" do
      create(:static_page, title: "About", slug: "about")
      get "/admin/static_pages/about/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns 404 for an unknown slug" do
      get "/admin/static_pages/does-not-exist/edit"
      expect(response).to have_http_status(:not_found)
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

    it "creates a translation through nested attributes" do
      patch "/admin/static_pages/#{page.id}", params: {
        static_page: {
          translations_attributes: [
            { locale: "ja", title: "概要", body: "<p>地域のニュース</p>" }
          ]
        }
      }
      expect(response).to redirect_to(admin_static_pages_path)
      expect(page.reload.translation_for(:ja)&.title).to eq("概要")
    end

    it "drops a translation row when every translatable field is blank" do
      expect {
        patch "/admin/static_pages/#{page.id}", params: {
          static_page: {
            translations_attributes: [
              { locale: "ja", title: "", seo_title: "", meta_description: "", body: "" }
            ]
          }
        }
      }.not_to change(StaticPageTranslation, :count)
    end
  end

  describe "GET /admin/static_pages/:id/edit form" do
    it "pre-builds a translation section per active non-English language" do
      page = create(:static_page, title: "About", slug: "about")
      get edit_admin_static_page_path(page)
      expect(response.body).to include('name="static_page[translations_attributes][0][locale]"')
      expect(response.body).to include('value="ja"')
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
