class HomeController < ApplicationController
  def index
    article_includes = [ :translations, :author, :category, { featured_image_attachment: :blob } ]

    @lead_story = Article.published.featured.includes(article_includes).order(published_at: :desc).first
    @latest_articles = Article.published.recent.includes(article_includes)
    @latest_articles = @latest_articles.where.not(id: @lead_story.id) if @lead_story
    @latest_articles = @latest_articles.limit(8)

    locations = Location.where(slug: %w[joetsu myoko]).index_by(&:slug)
    @joetsu = locations["joetsu"]
    @myoko  = locations["myoko"]

    @joetsu_articles = @joetsu ? Article.published.by_location(@joetsu).recent.includes(:translations).limit(4) : []
    @myoko_articles  = @myoko  ? Article.published.by_location(@myoko).recent.includes(:translations).limit(4) : []

    @breaking_articles = Article.published.breaking.recent.includes(:translations).limit(3)
  end
end
