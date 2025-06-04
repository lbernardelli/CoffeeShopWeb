# ☕ CoffeeShop Web

A Rails 8 e-commerce app built with Hotwire. Started from a plain Ruby domain model project and evolved into this.

## What's this about?

I had this plain Ruby project called [`CoffeeApp`](https://github.com/lbernardelli/CoffeeShop) - just domain models, services, tests, no framework. The idea was to practice OO design, SOLID principles, hexagonal architecture, all that good stuff.

Then I thought: what if I take these same models and build an actual web app with Rails 8 and Hotwire? Keep the clean architecture but make it interactive and fast.

So here we are.

## What it does

It's a coffee shop. You browse coffees, add them to cart, checkout. Pretty standard e-commerce stuff, but with some interesting implementation details:

- Real-time cart updates with Turbo Streams (no full page reloads)
- Payment gateway abstraction so you can swap Stripe/PayPal/whatever without touching business logic
- Dependency injection everywhere for easier testing
- All tests follow Sandi Metz principles from POODR
- Tailwind for UI because I'm not a designer

### The fun parts

Click "Add to Cart" and watch the cart count update instantly. Adjust quantities and see everything recalculate. Remove items with smooth animations. All without reloading the page - that's Hotwire doing its thing.

The payment system is abstracted. Right now it's using a mock gateway, but swapping it for Stripe is just:

```ruby
CheckoutService.new(order, payment_gateway: StripeGateway.new)
```

No changes to controllers, views, or business logic. That's the hexagonal architecture paying off.

## Tech

- Rails 8.0.3
- Ruby 3.4.1
- Hotwire (Turbo + Stimulus)
- Tailwind CSS 4
- PostgreSQL
- RSpec with FactoryBot

## Setup

```bash
git clone git@github.com:lbernardelli/CoffeeShopWeb.git
cd CoffeeShopWeb
bundle install
rails db:create db:migrate db:seed
bundle exec rspec  # run tests
bin/dev            # start server
```

Then go to `http://localhost:3000`

## Testing

I'm using dependency injection heavily, which makes testing way easier. Instead of mocking ActiveRecord or stubbing class methods, services just accept their dependencies:

```ruby
# In tests:
let(:payment_gateway) { instance_double(PaymentGateway) }
service = CheckoutService.new(order, payment_gateway: payment_gateway)

# Now you can easily verify behavior:
expect(payment_gateway).to receive(:charge).with(amount: order.grand_total)
```

Check `TESTING.md` for more details on the approach.

## Why this matters

This project shows:

1. You can keep clean architecture when moving from plain Ruby to Rails
2. Hotwire is really good for this kind of app
3. Hexagonal architecture makes swapping implementations trivial
4. Dependency injection makes testing way less painful
5. You don't need React for a modern UX

The original `CoffeeApp` was about 500 lines of Ruby. This Rails app adds authentication, views, controllers, Hotwire interactions, and a full test suite while keeping the domain logic clean.
