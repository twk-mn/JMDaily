require 'rails_helper'

RSpec.describe "Admin::Authors", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/authors" do
    it "returns success" do
      get admin_authors_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/authors/new" do
    it "returns success" do
      get new_admin_author_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/authors" do
    it "creates author" do
      expect {
        post admin_authors_path, params: {
          author: { name: "New Author", bio: "Bio text", role_title: "Reporter" }
        }
      }.to change(Author, :count).by(1)
      expect(response).to redirect_to(admin_authors_path)
    end

    it "re-renders with invalid params" do
      post admin_authors_path, params: { author: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/authors/:id/edit" do
    it "returns success when accessed by integer id" do
      author = create(:author)
      get "/admin/authors/#{author.id}/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns success when accessed by slug (since Author#to_param returns slug)" do
      create(:author, name: "Aya Tanaka", slug: "aya-tanaka")
      get "/admin/authors/aya-tanaka/edit"
      expect(response).to have_http_status(:success)
    end

    it "returns 404 for an unknown slug" do
      get "/admin/authors/does-not-exist/edit"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/authors/:id" do
    let!(:author) { create(:author) }

    it "updates author" do
      patch "/admin/authors/#{author.id}", params: { author: { name: "Updated Name" } }
      expect(response).to redirect_to(admin_authors_path)
      expect(author.reload.name).to eq("Updated Name")
    end

    it "creates a translation through nested attributes" do
      patch "/admin/authors/#{author.id}", params: {
        author: {
          translations_attributes: [
            { locale: "ja", role_title: "上級記者", bio: "新潟の政治を担当" }
          ]
        }
      }
      expect(response).to redirect_to(admin_authors_path)
      expect(author.reload.translation_for(:ja)&.bio).to eq("新潟の政治を担当")
    end

    it "drops a translation row when every translatable field is left blank" do
      expect {
        patch "/admin/authors/#{author.id}", params: {
          author: {
            translations_attributes: [
              { locale: "ja", role_title: "", bio: "" }
            ]
          }
        }
      }.not_to change(AuthorTranslation, :count)
    end
  end

  describe "GET /admin/authors/:id/edit form" do
    it "pre-builds a translation section per active non-English language" do
      author = create(:author, name: "Aya", slug: "aya")
      get edit_admin_author_path(author)
      expect(response.body).to include('name="author[translations_attributes][0][locale]"')
      expect(response.body).to include('value="ja"')
    end
  end

  describe "DELETE /admin/authors/:id" do
    it "destroys author without articles" do
      author = create(:author)
      expect {
        delete "/admin/authors/#{author.id}"
      }.to change(Author, :count).by(-1)
    end

    it "does not destroy author with articles" do
      author = create(:author)
      create(:article, :published, author: author)
      expect {
        delete "/admin/authors/#{author.id}"
      }.not_to change(Author, :count)
      expect(response).to redirect_to(admin_authors_path)
    end
  end
end
