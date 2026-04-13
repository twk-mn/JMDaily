FactoryBot.define do
  factory :contact_submission do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    subject { Faker::Lorem.sentence }
    message { Faker::Lorem.paragraph }
  end
end
