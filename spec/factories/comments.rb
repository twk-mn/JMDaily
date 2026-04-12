FactoryBot.define do
  factory :comment do
    article
    name { Faker::Name.name }
    email { Faker::Internet.email }
    body { Faker::Lorem.paragraph }
    status { "pending" }

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
