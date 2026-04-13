FactoryBot.define do
  factory :article_translation do
    article
    locale { "en" }
    sequence(:title) { |n| "Article Translation #{n}" }
    sequence(:slug) { |n| "article-translation-#{n}" }
    dek { Faker::Lorem.sentence }
  end
end
