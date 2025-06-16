# Payment Gateway Architecture

This module implements a payment processing system following **Hexagonal Architecture** (Ports & Adapters) and **SOLID principles**, specifically the **Open/Closed Principle**.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Core                          │
│                  (CheckoutService)                           │
│                         │                                    │
│                         ▼                                    │
│                ┌────────────────┐                            │
│                │ PaymentGateway │  ◄─── Port (Interface)    │
│                │   (Abstract)   │                            │
│                └────────────────┘                            │
│                         │                                    │
│          ┌──────────────┴──────────────┐                    │
│          ▼                              ▼                    │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │ MockPayment      │         │ StripePayment    │          │
│  │ Gateway          │         │ Gateway          │          │
│  │ (Adapter)        │         │ (Adapter)        │          │
│  └──────────────────┘         └──────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Core Principles

### 1. Dependency Inversion Principle
The `CheckoutService` depends on the **abstract** `PaymentGateway`, not concrete implementations. This allows different payment providers to be swapped without modifying the checkout logic.

### 2. Open/Closed Principle
The system is **open for extension** (add new payment gateways) but **closed for modification** (no changes needed to existing code).

### 3. Single Responsibility Principle
- `PaymentGateway`: Defines the payment interface
- `PaymentResult`: Encapsulates payment responses
- `CheckoutService`: Orchestrates checkout flow
- Adapters: Implement specific payment provider logic

## How to Add a New Payment Gateway

### Example: Adding Stripe Payment Gateway

**Step 1:** Create a new adapter implementing the `PaymentGateway` interface:

```ruby
# lib/coffee_app/payment/adapters/stripe_payment_gateway.rb
module CoffeeApp
  module Payment
    module Adapters
      class StripePaymentGateway < PaymentGateway
        def initialize(api_key:)
          @api_key = api_key
          @stripe = Stripe::Client.new(api_key: @api_key)
        end

        def charge(amount:, payment_details:, metadata: {})
          intent = @stripe.payment_intents.create(
            amount: (amount * 100).to_i, # Convert to cents
            currency: 'usd',
            payment_method: payment_details[:payment_method_id],
            metadata: metadata,
            confirm: true
          )

          PaymentResult.new(
            success: intent.status == 'succeeded',
            transaction_id: intent.id,
            message: intent.status == 'succeeded' ? 'Payment successful' : 'Payment failed',
            metadata: {
              amount: amount,
              status: intent.status
            }
          )
        rescue Stripe::StripeError => e
          PaymentResult.new(
            success: false,
            message: e.message,
            metadata: { error_code: e.code }
          )
        end

        def refund(transaction_id:, amount:)
          refund = @stripe.refunds.create(
            payment_intent: transaction_id,
            amount: (amount * 100).to_i
          )

          PaymentResult.new(
            success: refund.status == 'succeeded',
            transaction_id: refund.id,
            message: 'Refund processed',
            metadata: { amount: amount }
          )
        end

        def available?
          @api_key.present?
        end
      end
    end
  end
end
```

**Step 2:** Configure the gateway in an initializer:

```ruby
# config/initializers/payment_gateway.rb
Rails.application.configure do
  config.payment_gateway = if Rails.env.production?
    Payment::Adapters::StripePaymentGateway.new(
      api_key: ENV['STRIPE_SECRET_KEY']
    )
  else
    Payment::Adapters::MockPaymentGateway.new
  end
end
```

**Step 3:** Use dependency injection in the controller:

```ruby
# app/controllers/checkout_controller.rb
def process
  gateway = Rails.configuration.payment_gateway
  checkout_service = Services::CheckoutService.new(@cart, payment_gateway: gateway)

  result = checkout_service.process(
    shipping_params: shipping_address_params,
    payment_params: payment_details_params
  )
  # ... rest of the code
end
```

**That's it!** No changes to:
- ✅ `CheckoutService`
- ✅ Models
- ✅ Views
- ✅ Other controllers

## Available Adapters

### MockPaymentGateway
**Location:** `lib/coffee_app/payment/adapters/mock_payment_gateway.rb`

**Purpose:** Development and testing

**Test Cards:**
- `4111111111111111` → Approved
- `4000000000000002` → Declined (insufficient funds)
- `4000000000000127` → Gateway error

**Usage:**
```ruby
gateway = Payment::Adapters::MockPaymentGateway.new
result = gateway.charge(
  amount: 99.99,
  payment_details: { card_number: '4111111111111111' }
)
```

## Payment Gateway Interface

All payment gateways must implement:

### `charge(amount:, payment_details:, metadata: {})`
Process a payment charge.

**Parameters:**
- `amount` (BigDecimal): Amount to charge
- `payment_details` (Hash): Payment method details
- `metadata` (Hash): Additional transaction data

**Returns:** `PaymentResult`

### `refund(transaction_id:, amount:)`
Refund a previous transaction.

**Parameters:**
- `transaction_id` (String): Original transaction ID
- `amount` (BigDecimal): Amount to refund

**Returns:** `PaymentResult`

### `available?`
Check if the gateway is ready to process payments.

**Returns:** Boolean

## PaymentResult Value Object

Immutable object representing payment operation results:

```ruby
result = PaymentResult.new(
  success: true,
  transaction_id: 'txn_123',
  message: 'Payment approved',
  metadata: { card_last_four: '1111' }
)

result.success?         # => true
result.failure?         # => false
result.transaction_id   # => 'txn_123'
result.error_message    # => nil (only set on failure)
```

## Testing

When writing tests, inject a mock gateway:

```ruby
RSpec.describe CheckoutService do
  let(:mock_gateway) { instance_double(Payment::PaymentGateway) }
  let(:service) { CheckoutService.new(order, payment_gateway: mock_gateway) }

  it 'processes payment through the gateway' do
    expect(mock_gateway).to receive(:charge).and_return(
      PaymentResult.new(success: true, transaction_id: 'test_123')
    )

    result = service.process(shipping_params: {}, payment_params: {})
    expect(result.success?).to be_truthy
  end
end
```

## Benefits of This Architecture

1. **Easy Testing**: Mock the payment gateway in tests
2. **Environment-Specific Gateways**: Use mock in dev, real in production
3. **Multiple Payment Providers**: Support Stripe, PayPal, Square simultaneously
4. **Graceful Degradation**: Fall back to alternative gateway if one fails
5. **No Vendor Lock-in**: Switch providers without touching business logic
6. **Clean Separation**: Payment logic isolated from checkout flow
