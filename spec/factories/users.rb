FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123secure" }
    password_confirmation { "Password123secure" }
    role { "admin" }

    trait :editor do
      role { "editor" }
    end
  end
end
