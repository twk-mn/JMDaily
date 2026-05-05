require 'rails_helper'

RSpec.describe "Admin::Categories", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/categories" do
    it "returns success" do
      get admin_categories_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/categories/new" do
    it "returns success" do
      get new_admin_category_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/categories" do
    it "creates category" do
      expect {
        post admin_categories_path, params: { category: { name: "Sports", position: 1 } }
      }.to change(Category, :count).by(1)
      expect(response).to redirect_to(admin_categories_path)
    end

    it "re-renders with invalid params" do
      post admin_categories_path, params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/categories/:id/edit" do
    it "returns success when accessed by integer id" do
      category = create(:category)
      get "/admin/categories/#{category.id}/edit"
      expect(response).to have_http_status(:success)
    end

    # Category#to_param returns the slug, so URL helpers in the admin index
    # render `/admin/categories/<slug>/edit`. Both forms must resolve.
    it "returns success when accessed by slug" do
      create(:category, name: "News", slug: "news")
      get "/admin/categories/news/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns 404 for an unknown slug" do
      get "/admin/categories/does-not-exist/edit"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/categories/:id" do
    let!(:category) { create(:category) }

    it "updates category" do
      patch "/admin/categories/#{category.id}", params: { category: { name: "Updated" } }
      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.name).to eq("Updated")
    end

    it "creates a translation through nested attributes" do
      patch "/admin/categories/#{category.id}", params: {
        category: {
          translations_attributes: [
            { locale: "ja", name: "ニュース", description: "地域のニュース" }
          ]
        }
      }
      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.translation_for(:ja)&.name).to eq("ニュース")
    end

    it "drops a translation row when every translatable field is left blank" do
      expect {
        patch "/admin/categories/#{category.id}", params: {
          category: {
            translations_attributes: [
              { locale: "ja", name: "", description: "" }
            ]
          }
        }
      }.not_to change(CategoryTranslation, :count)
    end
  end

  describe "GET /admin/categories/:id/edit form" do
    it "pre-builds a translation section per active non-English language" do
      category = create(:category, name: "News", slug: "news")
      get edit_admin_category_path(category)
      expect(response.body).to include('name="category[translations_attributes][0][locale]"')
      expect(response.body).to include('value="ja"')
    end
  end

  describe "DELETE /admin/categories/:id" do
    it "destroys category without articles" do
      category = create(:category)
      expect {
        delete "/admin/categories/#{category.id}"
      }.to change(Category, :count).by(-1)
    end

    it "does not destroy category with articles" do
      category = create(:category)
      create(:article, :published, category: category)
      expect {
        delete "/admin/categories/#{category.id}"
      }.not_to change(Category, :count)
      expect(response).to redirect_to(admin_categories_path)
    end
  end

  describe "authentication" do
    it "redirects when not logged in" do
      reset!
      get admin_categories_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
