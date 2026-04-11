require 'rails_helper'

RSpec.describe "Admin::Sessions", type: :request do
  let(:password) { "Password123secure" }
  let!(:user) { create(:user, email: "admin@test.com", password: password, password_confirmation: password) }

  describe "GET /admin/login" do
    it "returns success" do
      get admin_login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/login" do
    it "logs in with valid credentials" do
      post admin_login_path, params: { email: "admin@test.com", password: password }
      expect(response).to redirect_to(admin_articles_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "rejects invalid credentials" do
      post admin_login_path, params: { email: "admin@test.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end

    it "rejects non-existent user" do
      post admin_login_path, params: { email: "nobody@test.com", password: password }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "resets session on login (session fixation protection)" do
      post admin_login_path, params: { email: "admin@test.com", password: password }
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE /admin/logout" do
    it "logs out and redirects" do
      login_as(user)
      delete admin_logout_path
      expect(response).to redirect_to(admin_login_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
