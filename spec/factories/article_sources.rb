FactoryBot.define do
  factory :article_source do
    article
    name { Faker::Company.name }
    url  { Faker::Internet.url(scheme: "https") }
    position { 0 }
  end
end
