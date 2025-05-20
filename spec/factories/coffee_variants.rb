FactoryBot.define do
  factory :coffee_variant do
    association :coffee
    size { "medium" }
    price { 15.99 }

    trait :small do
      size { "small" }
      price { 12.99 }
    end

    trait :medium do
      size { "medium" }
      price { 15.99 }
    end

    trait :large do
      size { "large" }
      price { 18.99 }
    end
  end
end
