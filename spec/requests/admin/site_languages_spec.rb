require 'rails_helper'

RSpec.describe "Admin::SiteLanguages", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:editor) { create(:user, :editor) }

  describe "authorization" do
    it "redirects anonymous requests to login" do
      post admin_site_languages_path, params: { site_language: { code: "ko" } }
      expect(response).to redirect_to(admin_login_path)
    end

    it "rejects non-admin users" do
      login_as(editor)
      post admin_site_languages_path, params: { site_language: { code: "ko" } }
      expect(response).to redirect_to(admin_articles_path)
      expect(SiteLanguage.find_by(code: "ko")).to be_nil
    end
  end

  describe "POST /admin/settings/languages (create)" do
    before { login_as(admin) }

    it "adds a language from the ISO whitelist" do
      expect {
        post admin_site_languages_path, params: { site_language: { code: "ko" } }
      }.to change(SiteLanguage, :count).by(1)
      expect(SiteLanguage.find_by(code: "ko")).to be_present
    end

    it "rejects codes outside the ISO whitelist" do
      expect {
        post admin_site_languages_path, params: { site_language: { code: "xx" } }
      }.not_to change(SiteLanguage, :count)
      expect(flash[:alert]).to include("supported list")
    end

    it "rejects duplicates" do
      expect {
        post admin_site_languages_path, params: { site_language: { code: "en" } }
      }.not_to change(SiteLanguage, :count)
    end
  end

  describe "POST .../deactivate" do
    before { login_as(admin) }
    let(:ja) { SiteLanguage.find_by(code: "ja") }

    it "hides the language without deleting rows" do
      post deactivate_admin_site_language_path(ja)
      expect(ja.reload.active).to be false
    end

    it "refuses to deactivate the required language" do
      en = SiteLanguage.find_by(code: "en")
      post deactivate_admin_site_language_path(en)
      expect(en.reload.active).to be true
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST .../activate" do
    before { login_as(admin) }
    let(:ja) { SiteLanguage.find_by(code: "ja") }

    it "reactivates a hidden language" do
      ja.update!(active: false)
      post activate_admin_site_language_path(ja)
      expect(ja.reload.active).to be true
    end
  end

  describe "DELETE .../:id (purge)" do
    before { login_as(admin) }
    let(:ja) { SiteLanguage.find_by(code: "ja") }

    it "refuses without typed confirmation" do
      ja.update!(active: false)
      expect {
        delete admin_site_language_path(ja)
      }.not_to change(SiteLanguage, :count)
      expect(flash[:alert]).to include("not confirmed")
    end

    it "refuses when the language is still active" do
      expect {
        delete admin_site_language_path(ja), params: { confirm: "ja" }
      }.not_to change(SiteLanguage, :count)
      expect(flash[:alert]).to include("Deactivate")
    end

    it "purges when deactivated and confirmation matches" do
      article = create(:article)
      create(:article_translation, article: article, locale: "ja", title: "JA", slug: "ja-slug")
      ja.update!(active: false)

      expect {
        delete admin_site_language_path(ja), params: { confirm: "ja" }
      }.to change(SiteLanguage, :count).by(-1)
      expect(ArticleTranslation.where(locale: "ja").count).to eq(0)
    end

    it "refuses to purge the required language" do
      en = SiteLanguage.find_by(code: "en")
      expect {
        delete admin_site_language_path(en), params: { confirm: "en" }
      }.not_to change(SiteLanguage, :count)
    end
  end

  describe "PATCH .../:id (edit name)" do
    before { login_as(admin) }
    let(:ja) { SiteLanguage.find_by(code: "ja") }

    it "updates display-only fields" do
      patch admin_site_language_path(ja), params: { site_language: { name: "Nihongo" } }
      expect(ja.reload.name).to eq("Nihongo")
    end

    it "ignores attempts to change the code" do
      patch admin_site_language_path(ja), params: { site_language: { name: "X", code: "xx" } }
      expect(ja.reload.code).to eq("ja")
    end
  end

  describe "POST .../reorder" do
    before { login_as(admin) }

    it "updates positions in the given order" do
      en = SiteLanguage.find_by(code: "en")
      ja = SiteLanguage.find_by(code: "ja")
      post reorder_admin_site_languages_path,
           params: { ordered_ids: [ ja.id, en.id ] },
           as: :json
      expect(ja.reload.position).to eq(0)
      expect(en.reload.position).to eq(1)
    end
  end
end
