FactoryBot.define do
  factory :order do
    association :user
    status { "cart" }
    total { 0.0 }

    trait :cart do
      status { "cart" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :completed do
      status { "completed" }
      shipping_name { "John Doe" }
      shipping_address { "123 Main St" }
      shipping_city { "New York" }
      shipping_state { "NY" }
      shipping_zip { "10001" }
      shipping_country { "US" }
      payment_method { "credit_card" }
      payment_transaction_id { "txn_#{SecureRandom.hex(10)}" }
    end

    trait :with_items do
      after(:create) do |order|
        coffee = create(:coffee, :with_variants)
        variant = coffee.coffee_variants.first
        create(:order_item, order: order, coffee_variant: variant, quantity: 2, price: variant.price)
        order.recalculate_total!
      end
    end
  end
end
