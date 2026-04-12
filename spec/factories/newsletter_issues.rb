FactoryBot.define do
  factory :newsletter_issue do
    sequence(:subject) { |n| "Newsletter Issue #{n}" }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { "draft" }

    trait :sent do
      status { "sent" }
      sent_at { 1.hour.ago }
      recipients_count { 42 }
    end
  end
end
