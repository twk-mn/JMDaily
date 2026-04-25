class ArticlesController < ApplicationController
  def show
    @translation = ArticleTranslation
      .where(locale: I18n.locale.to_s, slug: params[:id])
      .joins(:article)
      .merge(Article.published)
      .includes(article: [ :author, :category, :tags, :locations, :sources, :translations ])
      .first!

    @article = @translation.article
    @approved_comments = @article.comments.approved.recent
    @pending_comment_preview = lookup_pending_comment_preview(@article)

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

    @other_translations = @article.translations.reject { |t| t.locale == I18n.locale.to_s }

    @json_ld = build_json_ld
  end

  private

  # Find this session's just-posted pending comment for the current article,
  # if any, so we can render it inline with an "awaiting moderation" badge.
  # Once it's approved (or rejected), drop the session pointer so we don't
  # keep showing the badge.
  def lookup_pending_comment_preview(article)
    pending_id = session.dig(:pending_comments, article.id.to_s)
    return nil unless pending_id

    comment = article.comments.find_by(id: pending_id)
    if comment&.status == "pending"
      comment
    else
      session[:pending_comments]&.delete(article.id.to_s)
      nil
    end
  end

  def build_json_ld
    schema = {
      "@context": "https://schema.org",
      "@type": "NewsArticle",
      "headline": @translation.title,
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
      },
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": article_url(@article)
      }
    }
    schema[:image] = url_for(@article.featured_image) if @article.featured_image.attached?
    schema
  end
end
