FactoryBot.define do
  factory :author do
    name { Faker::Name.name }
    slug { nil } # let before_validation generate it
    bio { Faker::Lorem.paragraph }
    role_title { "Staff Writer" }
  end
end
