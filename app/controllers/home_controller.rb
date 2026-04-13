class HomeController < ApplicationController
  def index
    @lead_story = Article.published.featured.includes(:translations).order(published_at: :desc).first
    @latest_articles = Article.published.recent.includes(:translations)
    @latest_articles = @latest_articles.where.not(id: @lead_story.id) if @lead_story
    @latest_articles = @latest_articles.limit(8)

    @joetsu = Location.find_by(slug: "joetsu")
    @myoko = Location.find_by(slug: "myoko")

    @joetsu_articles = @joetsu ? Article.published.by_location(@joetsu).recent.includes(:translations).limit(4) : []
    @myoko_articles = @myoko ? Article.published.by_location(@myoko).recent.includes(:translations).limit(4) : []

    @breaking_articles = Article.published.breaking.recent.includes(:translations).limit(3)
  end
end
