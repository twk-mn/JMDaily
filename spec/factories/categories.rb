FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    slug { nil }
    position { 0 }
  end
end
