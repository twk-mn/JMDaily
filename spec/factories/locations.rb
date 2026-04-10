FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Location #{n}" }
    slug { nil }
  end
end
