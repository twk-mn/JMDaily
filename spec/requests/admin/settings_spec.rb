require 'rails_helper'

RSpec.describe "Admin::Settings", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:editor) { create(:user, :editor) }

  describe "authorization" do
    it "redirects anonymous requests to login" do
      get admin_settings_path
      expect(response).to redirect_to(admin_login_path)
    end

    it "redirects non-admin users away from settings" do
      login_as(editor)
      get admin_settings_path
      expect(response).to redirect_to(admin_articles_path)
    end
  end

  describe "GET /admin/settings" do
    before { login_as(admin) }

    it "renders the general tab by default" do
      get admin_settings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Site name")
    end

    it "renders the languages tab" do
      get admin_settings_tab_path(tab: "languages")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Site languages")
    end

    it "renders the newsletter tab with a provider dropdown" do
      get admin_settings_tab_path(tab: "newsletter")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Audience provider")
      expect(response.body).to include("<select")
      expect(response.body).to include("Resend")
    end

    it "404s for an unknown tab (blocked by route constraint)" do
      get "/admin/settings/bogus"
      expect(response.status).to eq(404)
    end
  end

  describe "PATCH /admin/settings" do
    before { login_as(admin) }

    it "saves whitelisted keys for the current tab" do
      patch admin_settings_path, params: { tab: "general", settings: { site_name: "New Name", tagline: "Hello" } }
      expect(response).to redirect_to(admin_settings_tab_path(tab: "general"))
      expect(Setting.get("site_name")).to eq("New Name")
      expect(Setting.get("tagline")).to eq("Hello")
    end

    it "ignores keys not in the current tab" do
      patch admin_settings_path, params: { tab: "general", settings: { not_a_real_key: "x" } }
      expect(Setting.where(key: "not_a_real_key")).to be_empty
    end

    it "writes an audit log entry" do
      expect {
        patch admin_settings_path, params: { tab: "general", settings: { site_name: "Audited" } }
      }.to change(AuditLog, :count).by(1)
    end
  end
end
