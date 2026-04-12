class ArticlesController < ApplicationController
  def show
    @article = Article.published.find_by!(slug: params[:id])
    @related_articles = Article.published
      .where(category: @article.category)
      .where.not(id: @article.id)
      .order(published_at: :desc)
      .limit(4)
    @approved_comments = @article.comments.approved.recent
  end
end
