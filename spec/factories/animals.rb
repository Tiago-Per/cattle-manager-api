FactoryBot.define do
  factory :animal do
    sequence(:identification) { |n| "TAG-#{n}" }
    category { "cow" }
    sex { "female" }
    status { "active" }
    birth_date { 1.year.ago.to_date }
  end
end
