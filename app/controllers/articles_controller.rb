class ArticlesController < ApplicationController
  def show
    @translation = ArticleTranslation
      .where(locale: I18n.locale.to_s, slug: params[:id])
      .joins(:article)
      .merge(Article.published)
      .includes(article: [ :author, :category, :tags, :locations, :sources, :translations ])
      .first!

    @article = @translation.article

    @related_articles = Article.published
      .where(category: @article.category)
      .where.not(id: @article.id)
      .includes(:translations)
      .order(published_at: :desc)
      .limit(4)

    @approved_comments = @article.comments.approved.recent

    @more_from_author = Article.published
      .where(author: @article.author)
      .where.not(id: @article.id)
      .includes(:translations)
      .order(published_at: :desc)
      .limit(3)
  end
end
