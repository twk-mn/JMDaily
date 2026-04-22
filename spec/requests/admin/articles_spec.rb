require 'rails_helper'

RSpec.describe "Admin::Articles", type: :request do
  let!(:user) { create(:user) }
  let!(:author) { create(:author) }
  let!(:category) { create(:category) }

  before { login_as(user) }

  describe "GET /admin/articles" do
    it "returns success" do
      get admin_articles_path
      expect(response).to have_http_status(:success)
    end

    it "lists articles" do
      article = create(:article, title: "Test Article", author: author, category: category)
      get admin_articles_path
      expect(response.body).to include("Test Article")
    end

    it "filters by status" do
      create(:article, :published, title: "Published One", author: author, category: category)
      create(:article, status: "draft", title: "Draft One", author: author, category: category)
      get admin_articles_path, params: { status: "draft" }
      expect(response.body).to include("Draft One")
      expect(response.body).not_to include("Published One")
    end

    it "filters by category" do
      other_cat = create(:category, name: "Other")
      create(:article, title: "Cat Article", category: category, author: author)
      create(:article, title: "Other Article", category: other_cat, author: author)
      get admin_articles_path, params: { category_id: category.id }
      expect(response.body).to include("Cat Article")
      expect(response.body).not_to include("Other Article")
    end

    it "searches by title" do
      create(:article, title: "Searchable Title", author: author, category: category)
      create(:article, title: "Other Article", author: author, category: category)
      get admin_articles_path, params: { q: "Searchable" }
      expect(response.body).to include("Searchable Title")
      expect(response.body).not_to include("Other Article")
    end
  end

  describe "GET /admin/articles/new" do
    it "returns success" do
      get new_admin_article_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/articles" do
    it "creates article with valid params" do
      expect {
        post admin_articles_path, params: {
          article: {
            title: "New Article", dek: "A dek", status: "draft",
            author_id: author.id, category_id: category.id
          }
        }
      }.to change(Article, :count).by(1)
      expect(response).to redirect_to(edit_admin_article_path(Article.last))
    end

    it "re-renders form with invalid params" do
      post admin_articles_path, params: {
        article: { title: "", author_id: author.id, category_id: category.id }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates an article with only the required (English) translation filled in" do
      expect {
        post admin_articles_path, params: {
          article: {
            status: "draft", author_id: author.id, category_id: category.id,
            translations_attributes: [
              { locale: "en", title: "EN only", slug: "en-only", dek: "English dek" },
              { locale: "ja", title: "", slug: "", dek: "", body: "", context_box: "",
                seo_title: "", meta_description: "" }
            ]
          }
        }
      }.to change(Article, :count).by(1)

      article = Article.last
      expect(article.translations.map(&:locale)).to eq([ "en" ])
    end

    it "saves both translations when both are filled in" do
      post admin_articles_path, params: {
        article: {
          status: "draft", author_id: author.id, category_id: category.id,
          translations_attributes: [
            { locale: "en", title: "EN title", slug: "en-title", dek: "English dek" },
            { locale: "ja", title: "JA title", slug: "ja-title", dek: "Japanese dek" }
          ]
        }
      }
      expect(Article.last.translations.map(&:locale)).to match_array(%w[en ja])
    end
  end

  describe "GET /admin/articles/:id (show)" do
    it "redirects to edit" do
      article = create(:article, author: author, category: category)
      get "/admin/articles/#{article.id}"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/admin/articles/")
      expect(response.location).to include("/edit")
    end
  end

  describe "GET /admin/articles/:id/edit" do
    it "returns success" do
      article = create(:article, author: author, category: category)
      get "/admin/articles/#{article.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/articles/:id" do
    let!(:article) { create(:article, author: author, category: category) }

    it "updates article" do
      patch "/admin/articles/#{article.id}", params: {
        article: { title: "Updated Title" }
      }
      expect(article.reload.title).to eq("Updated Title")
    end

    it "re-renders form with invalid params" do
      patch "/admin/articles/#{article.id}", params: {
        article: { status: "not_a_real_status" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/articles/:id" do
    it "destroys article" do
      article = create(:article, author: author, category: category)
      expect {
        delete "/admin/articles/#{article.id}"
      }.to change(Article, :count).by(-1)
      expect(response).to redirect_to(admin_articles_path)
    end
  end

  describe "POST /admin/articles/bulk" do
    let!(:article1) { create(:article, author: author, category: category) }
    let!(:article2) { create(:article, author: author, category: category) }

    it "archives selected articles" do
      post bulk_admin_articles_path, params: {
        article_ids: [ article1.id, article2.id ],
        bulk_action: "archive"
      }
      expect(article1.reload.status).to eq("archived")
      expect(article2.reload.status).to eq("archived")
      expect(response).to redirect_to(admin_articles_path)
    end

    it "publishes selected articles" do
      post bulk_admin_articles_path, params: {
        article_ids: [ article1.id ],
        bulk_action: "publish"
      }
      expect(article1.reload.status).to eq("published")
    end

    it "deletes selected articles" do
      expect {
        post bulk_admin_articles_path, params: {
          article_ids: [ article1.id ],
          bulk_action: "delete"
        }
      }.to change(Article, :count).by(-1)
    end

    it "redirects with alert for unknown action" do
      post bulk_admin_articles_path, params: {
        article_ids: [ article1.id ],
        bulk_action: "unknown"
      }
      expect(response).to redirect_to(admin_articles_path)
    end

    it "redirects with alert when no articles are selected" do
      post bulk_admin_articles_path, params: { bulk_action: "delete" }
      expect(response).to redirect_to(admin_articles_path)
      follow_redirect!
      expect(response.body).to include("No articles selected")
    end

    it "refuses to delete published articles" do
      article1.update!(status: "published", published_at: 1.day.ago)
      expect {
        post bulk_admin_articles_path, params: {
          article_ids: [ article1.id ],
          bulk_action: "delete"
        }
      }.not_to change(Article, :count)
      follow_redirect!
      expect(response.body).to include("Archive them first")
    end
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      reset!
      get admin_articles_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
