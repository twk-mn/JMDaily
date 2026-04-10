FactoryBot.define do
  factory :static_page do
    sequence(:title) { |n| "Page #{n}" }
    slug { nil }
  end
end
