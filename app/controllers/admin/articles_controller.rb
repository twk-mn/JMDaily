module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: [:show, :edit, :update, :destroy]

    def index
      @articles = Article.includes(:author, :category).order(updated_at: :desc)
      @articles = @articles.where(status: params[:status]) if params[:status].present?
      @articles = @articles.where(category_id: params[:category_id]) if params[:category_id].present?
      @articles = @articles.where(author_id: params[:author_id]) if params[:author_id].present?
      @articles = @articles.where("title ILIKE ?", "%#{Article.sanitize_sql_like(params[:q])}%") if params[:q].present?
    end

    def show
      redirect_to edit_admin_article_path(@article)
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
