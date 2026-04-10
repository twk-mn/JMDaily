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
    it "returns success" do
      category = create(:category)
      get "/admin/categories/#{category.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/categories/:id" do
    let!(:category) { create(:category) }

    it "updates category" do
      patch "/admin/categories/#{category.id}", params: { category: { name: "Updated" } }
      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.name).to eq("Updated")
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
