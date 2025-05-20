FactoryBot.define do
  factory :order_item do
    association :order
    association :coffee_variant
    quantity { 1 }
    price { 15.99 }
  end
end
