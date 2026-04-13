FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
    slug { nil }
    dek { Faker::Lorem.sentence }
    status { "draft" }
    featured { false }
    breaking { false }
    author
    category

    # Every article must have at least one translation to render in views.
    after(:create) do |article|
      next if article.translations.exists?

      create(:article_translation,
        article: article,
        locale: "en",
        title: article.title,
        slug: article.slug || article.title.parameterize,
        dek: article.dek)
    end

    trait :published do
      status { "published" }
      published_at { 1.hour.ago }
    end

    trait :scheduled do
      status { "scheduled" }
      published_at { 1.day.from_now }
    end

    trait :archived do
      status { "archived" }
    end

    trait :featured do
      published
      featured { true }
    end

    trait :breaking do
      published
      breaking { true }
    end
  end
end
