FactoryBot.define do
  factory :audit_log do
    user
    action { "update" }
    resource_type { "Article" }
    resource_id { 1 }
    resource_label { "Test Article" }
    ip_address { "127.0.0.1" }
    metadata { {} }
  end
end
