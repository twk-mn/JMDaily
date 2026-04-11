require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let!(:admin) { create(:user, role: "admin") }
  before { login_as(admin) }

  describe "GET /admin/users" do
    it "returns success for admin" do
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "redirects editors" do
      editor = create(:user, :editor)
      reset!
      login_as(editor)
      get admin_users_path
      expect(response).to redirect_to(admin_articles_path)
    end
  end

  describe "POST /admin/users" do
    it "creates a user with valid params" do
      expect {
        post admin_users_path, params: {
          user: {
            name: "New Editor",
            email: "editor@example.com",
            role: "editor",
            password: "ValidPass123!",
            password_confirmation: "ValidPass123!"
          }
        }
      }.to change(User, :count).by(1)
    end

    it "re-renders form with invalid params" do
      post admin_users_path, params: {
        user: { name: "", email: "bad", role: "admin", password: "short" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/users/:id" do
    let!(:other_user) { create(:user) }

    it "updates a user's name" do
      patch admin_user_path(other_user), params: { user: { name: "Updated Name" } }
      expect(other_user.reload.name).to eq("Updated Name")
    end

    it "cannot change own role" do
      patch admin_user_path(admin), params: { user: { role: "editor" } }
      expect(admin.reload.role).to eq("admin")
    end
  end

  describe "DELETE /admin/users/:id" do
    let!(:other_user) { create(:user) }

    it "destroys another user" do
      expect { delete admin_user_path(other_user) }
        .to change(User, :count).by(-1)
    end

    it "cannot delete own account" do
      expect { delete admin_user_path(admin) }
        .not_to change(User, :count)
    end
  end
end
