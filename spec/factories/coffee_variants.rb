FactoryBot.define do
  factory :coffee_variant do
    coffee { nil }
    size { "MyString" }
    price { "9.99" }
  end
end
