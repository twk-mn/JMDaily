FactoryBot.define do
  factory :ad do
    sequence(:name) { |n| "Test Ad #{n}" }
    ad_type        { "direct" }
    placement_zone { "homepage_mid" }
    status         { "active" }
    link_url       { "https://example.com/sponsor" }
    link_target    { "_blank" }
    priority       { 0 }

    trait :script do
      ad_type     { "custom_html" }
      script_code { %(<div class="custom-ad">Sponsor block</div>) }
      link_url    { nil }
    end
  end
end
