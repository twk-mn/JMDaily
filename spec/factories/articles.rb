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
