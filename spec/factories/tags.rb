FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
    slug { nil }
  end
end
