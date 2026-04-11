FactoryBot.define do
  factory :tip_submission do
    tip_body { Faker::Lorem.paragraph }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    read { false }
  end
end
