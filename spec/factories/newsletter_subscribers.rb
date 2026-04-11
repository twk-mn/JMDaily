FactoryBot.define do
  factory :newsletter_subscriber do
    sequence(:email) { |n| "subscriber#{n}@example.com" }
    confirmed_at { nil }
    unsubscribed_at { nil }

    trait :confirmed do
      confirmed_at { 1.day.ago }
      confirmation_token { nil }
    end

    trait :unsubscribed do
      confirmed_at { 1.day.ago }
      unsubscribed_at { 1.hour.ago }
      confirmation_token { nil }
    end
  end
end
