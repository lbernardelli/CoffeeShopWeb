FactoryBot.define do
  factory :coffee do
    sequence(:name) { |n| "Coffee #{n}" }
    description { "A delicious coffee from around the world" }
    roast_type { %w[light medium dark].sample }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :light_roast do
      roast_type { "light" }
    end

    trait :medium_roast do
      roast_type { "medium" }
    end

    trait :dark_roast do
      roast_type { "dark" }
    end

    trait :with_variants do
      after(:create) do |coffee|
        create(:coffee_variant, :small, coffee: coffee)
        create(:coffee_variant, :medium, coffee: coffee)
        create(:coffee_variant, :large, coffee: coffee)
      end
    end
  end
end
