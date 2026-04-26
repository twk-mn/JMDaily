FactoryBot.define do
  factory :correction do
    article
    body      { "An earlier version misstated the date of the event. The correct date is May 5." }
    posted_at { Time.current }
  end
end
