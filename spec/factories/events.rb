FactoryBot.define do
  factory :event do
    association :animal
    occurred_on { Date.current }

    trait :vaccination do
      event_type { "vaccination" }
      product_name { "Aftosa" }
    end

    trait :weight do
      event_type { "weight" }
      weight_kg { 250.5 }
    end

    trait :breeding do
      event_type { "breeding" }
      sire_identification { "TAG-SIRE-1" }
    end
  end
end
