module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: [ :show, :edit, :update, :destroy ]

    def index
      scope = Article.includes(:author, :category).order(updated_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
      scope = scope.where(author_id: params[:author_id]) if params[:author_id].present?
      scope = scope.where("title ILIKE ?", "%#{Article.sanitize_sql_like(params[:q])}%") if params[:q].present?
      @pagy, @articles = pagy(:offset, scope, limit: 25)
    end

    def show
      redirect_to edit_admin_article_path(@article)
    end

    def preview
      @article = Article.includes(:author, :category, :tags, :locations).find(params[:id])
      @related_articles = Article.published
                                 .where(category: @article.category)
                                 .where.not(id: @article.id)
                                 .order(published_at: :desc)
                                 .limit(4)
      render "articles/show", layout: "application"
    end

    def bulk
      articles = Article.where(id: params[:article_ids])
      count = articles.size

      case params[:bulk_action]
      when "publish"
        articles.each { |a| a.update(status: "published", published_at: a.published_at || Time.current) }
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} published."
      when "archive"
        articles.update_all(status: "archived")
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} archived."
      when "delete"
        articles.destroy_all
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} deleted."
      else
        redirect_to admin_articles_path, alert: "Unknown action."
      end
    end

    def new
      @article = Article.new(status: "draft")
    end

    def create
      @article = Article.new(article_params)

      if @article.save
        redirect_to edit_admin_article_path(@article), notice: "Article created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to edit_admin_article_path(@article), notice: "Article updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_articles_path, notice: "Article deleted."
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :slug, :dek, :status, :published_at,
        :featured_image, :featured_image_caption,
        :seo_title, :meta_description, :canonical_url,
        :source_notes, :article_type, :featured, :breaking,
        :author_id, :category_id, :body,
        tag_ids: [], location_ids: []
      )
    end
  end
end
