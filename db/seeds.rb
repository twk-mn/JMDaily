# Admin user — password must be set via ADMIN_PASSWORD env var in any environment
# Default is development-only and intentionally obvious so it is never accidentally used in production.
raise "Set ADMIN_PASSWORD env var in production" if Rails.env.production? && ENV["ADMIN_PASSWORD"].blank?

default_password = ENV.fetch("ADMIN_PASSWORD", "JMDaily2024Dev!")

admin = User.find_or_create_by!(email: "admin@jmdaily.com") do |u|
  u.name = "Admin"
  u.password = default_password
  u.password_confirmation = default_password
  u.role = "admin"
end
puts "Admin user ready: admin@jmdaily.com"

# Categories
categories = {
  "News" => { slug: "news", position: 1, description: "Breaking news and daily coverage from Joetsu and Myoko." },
  "Politics" => { slug: "politics", position: 2, description: "Local government, city council decisions, and political news." },
  "Business" => { slug: "business", position: 3, description: "Business openings, closures, and economic news." },
  "Community" => { slug: "community", position: 4, description: "Community stories, schools, and local initiatives." },
  "Weather & Travel" => { slug: "weather-travel", position: 5, description: "Weather updates, road closures, train disruptions, and travel information." },
  "Events" => { slug: "events", position: 6, description: "Local events, festivals, and seasonal activities." },
  "Opinion" => { slug: "opinion", position: 7, description: "Analysis, explainers, and opinion pieces." }
}

categories.each do |name, attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = name
    c.description = attrs[:description]
    c.position = attrs[:position]
  end
end
puts "Categories created."

# Locations
[ "Joetsu", "Myoko", "Itoigawa" ].each do |name|
  Location.find_or_create_by!(slug: name.parameterize) do |l|
    l.name = name
  end
end
puts "Locations created."

# Tags
tags = %w[snowfall city-council shinkansen road-closures tourism schools festivals infrastructure]
tags.each do |slug|
  Tag.find_or_create_by!(slug: slug) do |t|
    t.name = slug.titleize
  end
end
puts "Tags created."

# Default author
author = Author.find_or_create_by!(slug: "editorial") do |a|
  a.name = "Editorial"
  a.role_title = "Editor"
  a.bio = "The editorial team at Joetsu-Myoko Daily."
  a.user = admin
end
puts "Default author created."

# Static pages
pages = {
  "About" => { slug: "about", body: "<p>Joetsu-Myoko Daily is an independent English-language news publication covering Joetsu, Myoko, and the surrounding region in Niigata Prefecture, Japan.</p><p>We aim to provide accurate, timely, and relevant local news for English-speaking residents, visitors, and anyone interested in this part of Japan.</p>" },
  "Contact" => { slug: "contact", body: "<p>Have a story tip, correction, or question? We'd love to hear from you.</p><p>You can reach us using the form below, or email us directly at <strong>hello@jmdaily.com</strong>.</p>" },
  "Submit a Tip" => { slug: "submit-a-tip", body: "<p>Have a news tip or story suggestion? We want to hear from you.</p><p>Please use the contact form on our <a href='/contact'>contact page</a> to send us your tip. Include as much detail as possible — what happened, when, where, and any relevant context.</p><p>We protect the confidentiality of our sources.</p>" },
  "Privacy Policy" => { slug: "privacy-policy", body: "<p>Joetsu-Myoko Daily respects your privacy. This site does not use invasive tracking or sell personal data.</p><p>If you contact us via the contact form, we store your name, email, and message solely for the purpose of responding to your inquiry.</p><p>We may use privacy-respecting analytics to understand general traffic patterns. No personal data is shared with third parties.</p>" },
  "Terms" => { slug: "terms", body: "<p>By using this website, you agree to these terms of use.</p><p>All content published on Joetsu-Myoko Daily is protected by copyright. You may share articles with attribution and a link back to the original article.</p><p>We make every effort to ensure accuracy but cannot guarantee that all information is error-free. Corrections will be published promptly when errors are identified.</p>" },
  "Corrections Policy" => { slug: "corrections-policy", body: "<p>Accuracy is fundamental to our work. When we make a mistake, we correct it promptly and transparently.</p><p>If you believe we have published incorrect information, please contact us at <strong>hello@jmdaily.com</strong> or via our <a href='/contact'>contact form</a>.</p><p>Corrections will be clearly noted at the bottom of the relevant article with a description of what was changed and when.</p>" }
}

pages.each do |title, attrs|
  page = StaticPage.find_or_create_by!(slug: attrs[:slug]) do |p|
    p.title = title
  end
  # Always update the body in case it changed
  page.update!(body: attrs[:body]) if page.body.blank?
end
puts "Static pages created."

puts "\nSeeding complete! Log in at /admin/login with admin@jmdaily.com"
