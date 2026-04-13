xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Joetsu-Myoko Daily"
    xml.description "English-language local news for Joetsu, Myoko, and the surrounding region in Niigata, Japan."
    xml.link root_url
    xml.language "en"
    xml.tag! "atom:link", href: feed_url(format: :rss), rel: "self", type: "application/rss+xml"

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.description article.dek.presence || article.body.to_plain_text.truncate(300)
        xml.link article_url(article)
        xml.guid article_url(article)
        xml.pubDate article.published_at.rfc822
        xml.author article.author.name
        xml.category article.category.name
      end
    end
  end
end
