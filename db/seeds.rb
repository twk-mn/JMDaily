# Admin user — password must be set via ADMIN_PASSWORD env var in any environment
# Default is development-only and intentionally obvious so it is never accidentally used in production.
raise "Set ADMIN_PASSWORD env var in production" if Rails.env.production? && ENV["ADMIN_PASSWORD"].blank?

default_password = ENV.fetch("ADMIN_PASSWORD", "JMDaily2024Dev!")

# Site languages — English (required, non-deletable) plus Japanese as the
# initial optional translation. Admins can add, deactivate, and purge other
# languages from the admin Settings → Languages tab.
SiteLanguage.find_or_create_by!(code: "en") do |l|
  l.name        = "English"
  l.native_name = "English"
  l.flag_emoji  = "🇬🇧"
  l.position    = 0
  l.active      = true
  l.deletable   = false
end

SiteLanguage.find_or_create_by!(code: "ja") do |l|
  l.name        = "Japanese"
  l.native_name = "日本語"
  l.flag_emoji  = "🇯🇵"
  l.position    = 1
  l.active      = true
  l.deletable   = true
end
puts "Site languages ready."

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

# ---------------------------------------------------------------------------
# Sample content — development & test only.
#
# Everything above this line is the minimal set required to boot the site in
# any environment (admin user, languages, categories, default author, etc.).
# Below this line we populate enough realistic content to exercise the public
# site end-to-end without poking around in the admin: multiple authors with
# bios + social links, articles in both languages with translations, varied
# article types, breaking + featured flags, a correction, a couple of
# approved + pending comments, and a handful of ads exercising both global
# and locale-targeted placements.
#
# Re-running `db:seed` is safe — we short-circuit when sample articles
# already exist so previous edits aren't clobbered.
# ---------------------------------------------------------------------------

if Rails.env.production?
  puts "\nSeeding complete! Log in at /admin/login with admin@jmdaily.com"
  return
end

if Article.where.not(id: nil).exists?
  puts "Sample content already present — skipping. (Drop the database to re-seed.)"
  puts "\nSeeding complete! Log in at /admin/login with admin@jmdaily.com"
  return
end

puts "Seeding sample content for development..."

# Additional locations
[ "Nagano" ].each do |name|
  Location.find_or_create_by!(slug: name.parameterize) { |l| l.name = name }
end

# A few extra editorial profiles so author archive pages have variety.
authors = []
authors << author # the existing "Editorial" author
authors << Author.create!(
  name:        "Aya Tanaka",
  slug:        "aya-tanaka",
  role_title:  "Senior reporter",
  bio:         "Aya has covered local government in Niigata for over a decade. She speaks fluent English and Japanese.",
  twitter_url: "https://twitter.com/example_aya",
  bluesky_url: "https://bsky.app/profile/example.bsky.social",
  website_url: "https://example.com/aya"
)
authors << Author.create!(
  name:         "Daniel Park",
  slug:         "daniel-park",
  role_title:   "Travel & weather correspondent",
  bio:          "Daniel covers Myoko's ski season, weather disruption, and tourism stories for visiting readers.",
  instagram_url: "https://instagram.com/example_daniel",
  mastodon_url: "https://mastodon.social/@example_daniel"
)
authors << Author.create!(
  name:        "Hiroko Sato",
  slug:        "hiroko-sato",
  role_title:  "Community editor",
  bio:         "Hiroko grew up in Joetsu and writes about schools, festivals, and community life.",
  facebook_url: "https://facebook.com/example.hiroko",
  linkedin_url: "https://linkedin.com/in/example-hiroko"
)
puts "Authors created."

# Sample articles — paired EN/JA translations across categories.
sample_articles = [
  {
    en_title: "City council approves new bike lanes along Joetsu shoreline",
    ja_title: "上越市議会、海岸沿いに新しい自転車レーンを承認",
    en_dek:   "Construction is expected to begin in the spring, completing a 4-kilometer protected path connecting downtown Naoetsu with the coastal park.",
    ja_dek:   "工事は春頃に開始予定で、直江津中心部と海岸公園を結ぶ全長4キロの保護自転車道が完成する見込みです。",
    en_body:  "<p>The Joetsu City Council voted unanimously on Tuesday to fund a 4-kilometer protected bike lane along the shoreline. The project will connect downtown Naoetsu with the coastal park, addressing years of resident requests for safer cycling infrastructure.</p><p>Mayor Suzuki said the lanes were part of a broader push to encourage car-free transportation along the coast. Construction is expected to begin in March.</p>",
    ja_body:  "<p>上越市議会は火曜日、海岸沿いの全長4キロの保護自転車レーンへの予算を全会一致で承認しました。直江津中心部と海岸公園を結ぶこのプロジェクトは、より安全な自転車インフラを求める住民の長年の要望に応えるものです。</p><p>鈴木市長は、このレーンは海岸沿いの脱マイカー化の取り組みの一環であると述べました。工事は3月に開始される予定です。</p>",
    category: "politics", locations: %w[joetsu], tags: %w[city-council infrastructure],
    article_type: "news", featured: true, breaking: false, author_index: 1, days_ago: 0
  },
  {
    en_title: "Heavy snowfall closes Highway 18 over Myoko Pass",
    ja_title: "大雪で妙高峠の国道18号線が通行止めに",
    en_dek:   "Authorities are urging drivers to delay non-essential travel as a winter storm dropped 80cm of snow overnight.",
    ja_dek:   "冬の嵐で一晩に80cmの雪が降り、当局は不要不急の運転を控えるよう呼びかけています。",
    en_body:  "<p>The Niigata Prefectural police closed Highway 18 over Myoko Pass at 3am after a winter storm deposited 80cm of snow overnight. Drivers were diverted to alternative routes via Iiyama.</p><p>Ski resorts in the area welcomed the snowfall but warned that access remained difficult.</p>",
    ja_body:  "<p>新潟県警は、冬の嵐で一晩に80cmの雪が降り積もったため、午前3時に妙高峠の国道18号線を閉鎖しました。運転手は飯山経由の代替ルートへ迂回されています。</p><p>地域のスキー場は雪を歓迎しましたが、アクセスが依然として困難であることを警告しました。</p>",
    category: "weather-travel", locations: %w[myoko], tags: %w[snowfall road-closures],
    article_type: "news", featured: false, breaking: true, author_index: 2, days_ago: 1
  },
  {
    en_title: "Why the Hokuriku Shinkansen extension still divides Itoigawa",
    ja_title: "北陸新幹線延伸が今も糸魚川を二分する理由",
    en_dek:   "A decade after opening, residents debate whether the high-speed line has delivered on its economic promises.",
    ja_dek:   "開業から10年、新幹線がもたらすと約束された経済効果について住民の意見が分かれています。",
    en_body:  "<p>Ten years after the Hokuriku Shinkansen reached Itoigawa, the line has reshaped the local economy in ways both expected and surprising. Tourism numbers have risen sharply, but small retailers near the old Hokuriku Line stations report fewer visitors.</p><p>This explainer walks through the trade-offs Itoigawa has made — and what residents wish had been done differently.</p>",
    ja_body:  "<p>北陸新幹線が糸魚川に到達してから10年、この路線は地域経済を予想通りにも、また驚くような形でも変えてきました。観光客数は大幅に増加しましたが、旧北陸本線駅周辺の小売店は来店者の減少を報告しています。</p><p>この解説記事では、糸魚川が行ったトレードオフと、住民が違った形で行われていればと思うことについて検討します。</p>",
    category: "business", locations: %w[itoigawa], tags: %w[shinkansen tourism],
    article_type: "explainer", featured: false, breaking: false, author_index: 0, days_ago: 3
  },
  {
    en_title: "Kamigawa Elementary celebrates 150th anniversary",
    ja_title: "上川小学校が創立150周年を祝う",
    en_dek:   "Students, alumni, and teachers gathered Saturday to mark a century and a half of education in central Joetsu.",
    ja_dek:   "土曜日、生徒、卒業生、教師が集まり、上越中心部での150年にわたる教育の節目を祝いました。",
    en_body:  "<p>Kamigawa Elementary School marked its 150th anniversary on Saturday with a ceremony attended by current students, alumni, and former teachers. The school first opened its doors in 1875, just three years after Japan's modern education system was established.</p><p>Speakers reflected on how the community had changed — and how the school's role had stayed remarkably consistent.</p>",
    ja_body:  "<p>上川小学校は土曜日、現役の生徒、卒業生、元教師が出席する記念式典を開催し、創立150周年を祝いました。同校は、日本の近代教育制度が確立されてからわずか3年後の1875年に開校しました。</p><p>スピーカーは、地域社会がどのように変化してきたか、そして学校の役割がどれほど一貫してきたかについて振り返りました。</p>",
    category: "community", locations: %w[joetsu], tags: %w[schools],
    article_type: "feature", featured: true, breaking: false, author_index: 3, days_ago: 5
  },
  {
    en_title: "Spring Hanami calendar: where to see cherry blossoms in 2026",
    ja_title: "2026年春の花見カレンダー：桜の名所案内",
    en_dek:   "From Takada Park's nighttime illuminations to quiet rural shrines, our pick of the best spots and dates.",
    ja_dek:   "高田公園の夜桜ライトアップから静かな田舎の神社まで、おすすめのスポットと開花日をご案内します。",
    en_body:  "<p>Cherry blossom season is one of the highlights of the year in Joetsu and Myoko. Takada Park's 4,000 cherry trees and nighttime illuminations draw visitors from across Japan and overseas.</p><p>Below, our guide to the best places, the rough timing for each, and a few quieter recommendations off the main routes.</p>",
    ja_body:  "<p>桜のシーズンは上越と妙高で1年で最も注目される時期の一つです。高田公園の4,000本の桜と夜桜のライトアップは、日本中、海外からも観光客を集めます。</p><p>以下では、おすすめの場所、それぞれの大まかな時期、そして主要ルートから外れた静かなおすすめスポットをご案内します。</p>",
    category: "events", locations: %w[joetsu], tags: %w[festivals tourism],
    article_type: "feature", featured: false, breaking: false, author_index: 2, days_ago: 7
  },
  {
    en_title: "Analysis: What the new tourism tax means for Myoko businesses",
    ja_title: "分析：新観光税が妙高の事業者にとって意味するもの",
    en_dek:   "The 200-yen-per-night levy starts in April. We talked to four hotel operators about how they plan to handle it.",
    ja_dek:   "1泊200円の宿泊税が4月から始まります。4軒のホテル経営者にどう対応する予定か聞きました。",
    en_body:  "<p>Myoko's new tourism tax — 200 yen per overnight stay — takes effect on April 1. The city expects the levy to raise around 80 million yen annually for visitor infrastructure.</p><p>We talked to four hotel operators across price points to understand how they're planning to absorb, pass through, or communicate the new charge.</p>",
    ja_body:  "<p>妙高市の新しい観光税（1泊200円）が4月1日から施行されます。市はこの徴収により年間約8000万円が観光インフラのために集まると見込んでいます。</p><p>新料金を吸収するか、転嫁するか、伝達するか、各価格帯の4軒のホテル経営者に話を聞きました。</p>",
    category: "business", locations: %w[myoko], tags: %w[tourism],
    article_type: "analysis", featured: false, breaking: false, author_index: 1, days_ago: 10
  },
  {
    en_title: "Opinion: Joetsu needs more — and better — bilingual signage",
    ja_title: "意見：上越にはもっと、より良い二言語表記が必要だ",
    en_dek:   "As tourism rebounds, our patchwork of English signs is sending mixed messages.",
    ja_dek:   "観光が回復する中、ばらばらな英語表記が混乱したメッセージを発信しています。",
    en_body:  "<p>Walk from Joetsu-Myoko Station to Takada Castle and you'll pass through three distinct eras of bilingual signage — each with different conventions, fonts, and quality of translation.</p><p>This piece argues that consolidated, professionally translated signage is overdue, and lays out a possible path forward.</p>",
    ja_body:  "<p>上越妙高駅から高田城まで歩くと、3つの異なる時代の二言語表記が見られます。それぞれ異なる慣例、フォント、翻訳品質を持っています。</p><p>この記事では、統一された専門的に翻訳された表記が遅きに失していると主張し、今後の道筋を示します。</p>",
    category: "opinion", locations: %w[joetsu], tags: %w[infrastructure tourism],
    article_type: "news", featured: false, breaking: false, author_index: 3, days_ago: 14
  }
]

sample_articles.each do |spec|
  category = Category.find_by!(slug: spec[:category])
  author   = authors[spec[:author_index]]
  article  = Article.create!(
    title:        spec[:en_title],
    slug:         spec[:en_title].parameterize,
    dek:          spec[:en_dek],
    status:       "published",
    published_at: spec[:days_ago].days.ago,
    article_type: spec[:article_type],
    featured:     spec[:featured],
    breaking:     spec[:breaking],
    author:       author,
    category:     category
  )

  ArticleTranslation.create!(
    article: article, locale: "en",
    title: spec[:en_title], slug: spec[:en_title].parameterize,
    dek: spec[:en_dek], body: spec[:en_body]
  )
  ArticleTranslation.create!(
    article: article, locale: "ja",
    title: spec[:ja_title], slug: spec[:en_title].parameterize, # JA slug reuses parameterized EN title for ASCII safety
    dek: spec[:ja_dek], body: spec[:ja_body]
  )

  spec[:tags].each do |tag_slug|
    tag = Tag.find_by(slug: tag_slug)
    article.tags << tag if tag
  end
  spec[:locations].each do |loc_slug|
    loc = Location.find_by(slug: loc_slug)
    article.locations << loc if loc
  end
end
puts "#{sample_articles.size} sample articles created."

# A correction on one article so the corrections aside is exercised.
article_with_correction = Article.find_by(slug: "city-council-approves-new-bike-lanes-along-joetsu-shoreline")
if article_with_correction
  Correction.create!(
    article: article_with_correction,
    body:    "An earlier version of this article said construction begins in the autumn. The mayor's office has clarified the project will start in March.",
    posted_at: 6.hours.ago
  )
end

# Mixed-status comments on one of the articles so admin moderation has data.
busy_article = Article.find_by(slug: "heavy-snowfall-closes-highway-18-over-myoko-pass")
if busy_article
  Comment.create!(article: busy_article, name: "Skier", email: "skier@example.com",
                  body: "Thanks for the quick update — saved my morning commute.", status: "approved")
  Comment.create!(article: busy_article, name: "Local", email: "local@example.com",
                  body: "Highway 18 closes every winter. Why is this still news?", status: "approved")
  Comment.create!(article: busy_article, name: "Spammy McSpammer", email: "spam@example.com",
                  body: "Buy cheap winter tires! Click here.", status: "pending")
end

# Sample ads — one global, plus a pair of locale-targeted ads when the
# target_locale column exists (added in #89). The check keeps this seed
# usable on branches that pre-date that migration.
Ad.find_or_create_by!(name: "House promo — every locale") do |ad|
  ad.ad_type        = "custom_html"
  ad.placement_zone = "homepage_mid"
  ad.status         = "active"
  ad.priority       = 1
  ad.script_code    = '<div class="p-6 text-center bg-indigo-50 dark:bg-indigo-950/30 rounded-lg"><p class="text-sm font-medium text-indigo-700 dark:text-indigo-300">Got a story tip? <a href="/en/submit-a-tip" class="underline">Send it to us</a>.</p></div>'
end

if Ad.column_names.include?("target_locale")
  Ad.find_or_create_by!(name: "EN — Visit Myoko") do |ad|
    ad.ad_type        = "custom_html"
    ad.placement_zone = "article_inline"
    ad.status         = "active"
    ad.priority       = 5
    ad.target_locale  = "en"
    ad.sponsor_label  = "Sponsored by Visit Myoko"
    ad.script_code    = '<div class="p-4 text-center border border-gray-200 dark:border-gray-800 rounded-lg"><p class="text-sm">Plan your Myoko ski trip — guides, gear rental, and lodging.</p></div>'
  end
  Ad.find_or_create_by!(name: "JA — 妙高観光協会") do |ad|
    ad.ad_type        = "custom_html"
    ad.placement_zone = "article_inline"
    ad.status         = "active"
    ad.priority       = 5
    ad.target_locale  = "ja"
    ad.sponsor_label  = "妙高観光協会の広告"
    ad.script_code    = '<div class="p-4 text-center border border-gray-200 dark:border-gray-800 rounded-lg"><p class="text-sm">妙高のスキー旅行のご案内 — ガイド、レンタル、宿泊。</p></div>'
  end
  puts "Sample ads created (global + EN + JA)."
else
  puts "Sample ads created (global only — locale-targeted ads require the target_locale migration from #89)."
end

puts "\nSeeding complete! Log in at /admin/login with admin@jmdaily.com"
