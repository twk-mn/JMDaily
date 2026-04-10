SitemapGenerator::Sitemap.default_host = "https://jmdaily.com"

SitemapGenerator::Sitemap.create do
  # Static pages
  add about_path, changefreq: "monthly"
  add contact_path, changefreq: "monthly"
  add search_path, changefreq: "weekly"

  # Categories
  Category.find_each do |category|
    add "/#{category.slug}", changefreq: "daily"
  end

  # Locations
  Location.find_each do |location|
    add location_path(location), changefreq: "daily"
  end

  # Articles
  Article.published.find_each do |article|
    add article_path(article), lastmod: article.updated_at, changefreq: "weekly"
  end

  # Authors
  Author.find_each do |author|
    add author_path(author, slug: author.slug), changefreq: "weekly"
  end

  # Tags
  Tag.find_each do |tag|
    add tag_path(tag, slug: tag.slug), changefreq: "weekly"
  end
end
