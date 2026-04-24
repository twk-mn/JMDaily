module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: [ :show, :edit, :update, :destroy ]

    def index
      scope = Article.includes(:author, :category, :translations).order(updated_at: :desc)
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
      @article = Article.includes(:author, :category, :tags, :locations, :sources, :translations,
                                  featured_image_attachment: :blob).find(params[:id])
      @translation = @article.translation_for(I18n.locale) || @article.translations.first

      card_includes = [ :translations, { featured_image_attachment: :blob } ]
      @related_articles = Article.published
                                 .where(category: @article.category)
                                 .where.not(id: @article.id)
                                 .includes(card_includes)
                                 .order(published_at: :desc)
                                 .limit(4)
      @more_from_author = Article.published
                                 .where(author: @article.author)
                                 .where.not(id: @article.id)
                                 .includes(card_includes)
                                 .order(published_at: :desc)
                                 .limit(3)
      @approved_comments = @article.comments.approved.recent
      @other_translations = @article.translations.reject { |t| t.locale == I18n.locale.to_s }
      @json_ld = build_preview_json_ld

      render "articles/show", layout: "application"
    end

    def bulk
      ids = Array(params[:article_ids]).map(&:to_i).select(&:positive?)
      if ids.empty?
        redirect_to admin_articles_path, alert: "No articles selected." and return
      end

      articles = Article.where(id: ids)
      count = articles.size

      case params[:bulk_action]
      when "publish"
        articles.each { |a| a.update(status: "published", published_at: a.published_at || Time.current) }
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} published."
      when "archive"
        articles.update_all(status: "archived")
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} archived."
      when "delete"
        publishable = articles.where(status: "published").count
        if publishable > 0
          redirect_to admin_articles_path, alert: "Cannot delete published articles. Archive them first." and return
        end
        articles.destroy_all
        redirect_to admin_articles_path, notice: "#{count} #{"article".pluralize(count)} deleted."
      else
        redirect_to admin_articles_path, alert: "Unknown action."
      end
    end

    def new
      @article = Article.new(status: "draft")
      # Pre-build one translation per supported locale so the form renders all tabs
      Article.supported_locales.each do |locale|
        @article.translations.build(locale: locale)
      end
      @article.sources.build
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
      # Ensure a translation record exists for every supported locale
      Article.supported_locales.each do |locale|
        @article.translations.find_or_initialize_by(locale: locale)
      end
      @article.sources.build if @article.sources.empty?
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
      @article = Article.includes(:translations, :sources).find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :slug, :status, :published_at,
        :featured_image, :featured_image_alt, :featured_image_caption,
        :canonical_url, :source_notes, :article_type, :featured, :breaking,
        :author_id, :category_id,
        tag_ids: [], location_ids: [],
        translations_attributes: [
          :id, :locale, :title, :slug, :dek, :body, :context_box,
          :seo_title, :meta_description
        ],
        sources_attributes: [ :id, :name, :url, :position, :_destroy ]
      )
    end

    def build_preview_json_ld
      schema = {
        "@context": "https://schema.org",
        "@type": "NewsArticle",
        "headline": @translation&.title,
        "description": @article.effective_meta_description(@translation),
        "datePublished": @article.published_at&.iso8601,
        "dateModified": @article.updated_at.iso8601,
        "author": {
          "@type": "Person",
          "name": @article.author.name,
          "url": author_url(@article.author, slug: @article.author.slug)
        },
        "publisher": {
          "@type": "Organization",
          "name": "Joetsu-Myoko Daily"
        }
      }
      schema[:image] = url_for(@article.featured_image) if @article.featured_image.attached?
      schema
    end
  end
end
