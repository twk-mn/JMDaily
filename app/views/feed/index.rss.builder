xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom",
                         "xmlns:dc": "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    if @locale == "ja"
      xml.title "上越妙高デイリー"
      xml.description "新潟県上越市・妙高市のローカルニュース"
      xml.language "ja"
    else
      xml.title "Joetsu-Myoko Daily"
      xml.description "English-language local news for Joetsu, Myoko, and the surrounding region in Niigata, Japan."
      xml.language "en"
    end

    xml.link "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}/#{@locale}"
    xml.tag! "atom:link",
      href: feed_url(format: :rss, locale: @locale),
      rel: "self",
      type: "application/rss+xml"

    @articles.each do |article|
      translation = article.translation_for(@locale) || article.translation_for("en") || article.translations.first
      next unless translation

      xml.item do
        xml.title translation.title
        xml.description translation.dek.presence ||
                         translation.body&.to_plain_text&.truncate(300) ||
                         ""
        xml.link "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}/#{translation.locale}/articles/#{translation.slug}"
        xml.guid "https://#{ENV.fetch('APP_HOST', 'jmdaily.com')}/#{translation.locale}/articles/#{translation.slug}",
                 isPermaLink: "true"
        xml.pubDate article.published_at.rfc822
        xml.tag! "dc:creator", article.author.name
        xml.category article.category.name
      end
    end
  end
end
