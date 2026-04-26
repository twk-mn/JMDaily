class HomeController < ApplicationController
  def index
    article_includes = [ :translations, :author, :category, { featured_image_attachment: :blob } ]

    # Prefer an editorially-featured article; fall back to the most recent
    # so the hero always has content on quieter news days.
    @lead_story = Article.published.featured.includes(article_includes).order(published_at: :desc).first ||
                  Article.published.recent.includes(article_includes).first

    recent_scope = Article.published.recent.includes(article_includes)
    recent_scope = recent_scope.where.not(id: @lead_story.id) if @lead_story

    @secondary_stories = recent_scope.limit(3)
    excluded_hero_ids = [ @lead_story&.id, *@secondary_stories.map(&:id) ].compact

    news_category = Category.find_by(slug: "news")
    @local_news_articles = if news_category
      Article.published.where(category: news_category).where.not(id: excluded_hero_ids)
        .recent.includes(article_includes).limit(6)
    else
      Article.none
    end

    locations = Location.where(slug: SiteConfig::HOMEPAGE_LOCATION_SLUGS).index_by(&:slug)
    @joetsu = locations[SiteConfig::HOMEPAGE_LOCATION_SLUGS[0]]
    @myoko  = locations[SiteConfig::HOMEPAGE_LOCATION_SLUGS[1]]

    @joetsu_articles = @joetsu ? Article.published.by_location(@joetsu).recent.includes(:translations).limit(4) : []
    @myoko_articles  = @myoko  ? Article.published.by_location(@myoko).recent.includes(:translations).limit(4) : []
  end
end
