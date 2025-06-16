# Orders Price Abstractions

This directory contains encapsulated value objects and service objects for handling order-related pricing, tax, and shipping calculations.

## Core Objects

### Money (`money.rb`)
Value object for handling monetary values with precision.

**Features:**
- Multi-currency support (USD, EUR, GBP, JPY, BRL, etc.)
- Arithmetic operations (`+`, `-`, `*`, `/`)
- Comparison operations (`<`, `>`, `==`, etc.)
- Currency formatting (`$1,234.56`)
- Currency conversion support

**Example:**
```ruby
price = Orders::Money.new(10.50)
tax = price * 0.09
total = price + tax
formatted = total.format # => "$11.45"
```

### TaxCalculator (`tax_calculator.rb`)
Service for calculating taxes on orders.

**Features:**
- Default 9% tax rate (configurable)
- Returns Money objects
- Validation

**Example:**
```ruby
calculator = Orders::TaxCalculator.new(rate: 0.09)
amount = Orders::Money.new(100.00)
tax = calculator.calculate(amount) # => Orders::Money($9.00)
```

### ShippingCalculator (`shipping_calculator.rb`)
Service for calculating shipping costs.

**Features:**
- Free shipping over $50 (configurable)
- $5.99 standard cost (configurable)
- Remaining amount for free shipping helper

**Example:**
```ruby
calculator = Orders::ShippingCalculator.new
amount = Orders::Money.new(45.00)
cost = calculator.calculate(amount) # => Orders::Money($5.99)
remaining = calculator.remaining_for_free_shipping(amount) # => Orders::Money($5.00)
```

## Extended Calculators (Not Currently Used)

These are ready-to-use abstractions for future features:

### RegionalTaxCalculator (`regional_tax_calculator.rb`)
Extends TaxCalculator with state/country-specific rates.

**Features:**
- Pre-configured US state tax rates (CA: 7.25%, TX: 6.25%, etc.)
- International VAT/GST rates (UK: 20%, Canada: 5%, etc.)
- Tax exemptions (Alaska has no state tax)
- Tax name display (VAT, GST, Sales Tax)

**Example:**
```ruby
# California sales tax
ca_tax = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
tax = ca_tax.calculate(Orders::Money.new(100.00)) # => $7.25

# UK VAT
uk_tax = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
tax = uk_tax.calculate(Orders::Money.new(100.00)) # => £20.00
```

### PromotionalShippingCalculator (`promotional_shipping_calculator.rb`)
Extends ShippingCalculator with time-based promotions.

**Features:**
- Date-based promotions
- Custom promotional thresholds
- Reduced promotional shipping costs
- Discount calculation

**Example:**
```ruby
# Holiday promotion: free shipping over $25, otherwise $2.99
promo = Orders::PromotionalShippingCalculator.new(
  promotion_name: "Holiday Free Shipping",
  start_date: Date.new(2025, 12, 1),
  end_date: Date.new(2025, 12, 31),
  promotional_threshold: Orders::Money.new(25.00),
  promotional_cost: Orders::Money.new(2.99)
)

cost = promo.calculate(Orders::Money.new(30.00), date: Date.new(2025, 12, 15))
# => Orders::Money($0.00) - Free during promotion!

discount = promo.shipping_discount(Orders::Money.new(30.00), date: Date.new(2025, 12, 15))
# => Orders::Money($5.99) - Customer saved $5.99!
```

### TieredShippingCalculator (`tiered_shipping_calculator.rb`)
Service for multiple shipping speed options.

**Features:**
- Multiple shipping tiers (Standard, Express, Overnight)
- Per-tier free shipping thresholds
- Delivery time estimates
- Cutoff time handling
- Weekend skipping

**Default Tiers:**
- **Standard**: $5.99, free over $50, 5 business days
- **Express**: $12.99, free over $100, 2 business days
- **Overnight**: $24.99, never free, 1 business day

**Example:**
```ruby
calculator = Orders::TieredShippingCalculator.new
amount = Orders::Money.new(45.00)

# Get all available options
tiers = calculator.available_tiers(amount)
# => [
#   { name: "Standard Shipping", cost: $5.99, delivery_days: 5, ... },
#   { name: "Express Shipping", cost: $12.99, delivery_days: 2, ... },
#   { name: "Overnight Shipping", cost: $24.99, delivery_days: 1, ... }
# ]

# Calculate specific tier
cost = calculator.calculate(amount, tier_name: "Express Shipping")
# => Orders::Money($12.99)

# Get delivery estimate
delivery = calculator.estimated_delivery_date(
  tier_name: "Express Shipping",
  order_time: Time.current
)
# => Date (2 business days from now)
```

## Usage in Order Model

Currently the Order model uses simple calculations. To use these abstractions:

```ruby
class Order < ApplicationRecord
  def subtotal
    Orders::Money.new(total)
  end

  def tax
    tax_calculator.calculate(subtotal)
  end

  def shipping_cost
    shipping_calculator.calculate(subtotal)
  end

  private

  def tax_calculator
    # Use regional calculator based on shipping state
    @tax_calculator ||= Orders::RegionalTaxCalculator.new(
      region: shipping_state,
      region_type: :state
    )
  end

  def shipping_calculator
    # Use promotional calculator during holidays
    @shipping_calculator ||= Orders::PromotionalShippingCalculator.new(...)
    # Or use tiered calculator for express options
    @shipping_calculator ||= Orders::TieredShippingCalculator.new
  end
end
```

## Testing

All calculators have comprehensive specs in `spec/models/orders/`:
- `money_spec.rb` - 46 examples
- `tax_calculator_spec.rb` - 20 examples
- `shipping_calculator_spec.rb` - 23 examples
- `regional_tax_calculator_spec.rb` - 16 examples
- `promotional_shipping_calculator_spec.rb` - 15 examples
- `tiered_shipping_calculator_spec.rb` - 27 examples

Run all specs:
```bash
bundle exec rspec spec/models/orders/
```
