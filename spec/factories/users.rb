FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :whatsapp_subscriber do
      whatsapp_opt_in { true }
      sequence(:phone_number) { |n| "+1555000#{n.to_s.rjust(4, '0')}" }
    end
  end
end
