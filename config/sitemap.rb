SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}"

SitemapGenerator::Sitemap.create do
  # Static pages — both locales
  ArticleTranslation::LOCALES.each do |locale|
    add "/#{locale}", changefreq: "daily", priority: 1.0
    add "/#{locale}/about", changefreq: "monthly"
    add "/#{locale}/contact", changefreq: "monthly"
    add "/#{locale}/search", changefreq: "weekly"
  end

  # Categories
  Category.find_each do |category|
    ArticleTranslation::LOCALES.each do |locale|
      add "/#{locale}/#{category.slug}", changefreq: "daily"
    end
  end

  # Locations
  Location.find_each do |location|
    ArticleTranslation::LOCALES.each do |locale|
      add "/#{locale}/locations/#{location.slug}", changefreq: "daily"
    end
  end

  # Articles — one entry per translation so search engines get the right locale URL
  Article.published.includes(:translations).find_each do |article|
    article.translations.each do |translation|
      add "/#{translation.locale}/articles/#{translation.slug}",
          lastmod: article.updated_at,
          changefreq: "weekly",
          priority: 0.8
    end
  end

  # Authors
  Author.find_each do |author|
    add "/en/authors/#{author.slug}", changefreq: "weekly"
  end

  # Tags
  Tag.find_each do |tag|
    ArticleTranslation::LOCALES.each do |locale|
      add "/#{locale}/tags/#{tag.slug}", changefreq: "weekly"
    end
  end
end
