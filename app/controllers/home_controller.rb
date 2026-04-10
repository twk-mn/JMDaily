class HomeController < ApplicationController
  def index
    @lead_story = Article.published.featured.order(published_at: :desc).first
    @latest_articles = Article.published.recent
    @latest_articles = @latest_articles.where.not(id: @lead_story.id) if @lead_story
    @latest_articles = @latest_articles.limit(8)

    @joetsu = Location.find_by(slug: "joetsu")
    @myoko = Location.find_by(slug: "myoko")

    @joetsu_articles = @joetsu ? Article.published.by_location(@joetsu).recent.limit(4) : []
    @myoko_articles = @myoko ? Article.published.by_location(@myoko).recent.limit(4) : []

    @breaking_articles = Article.published.breaking.recent.limit(3)
  end
end
