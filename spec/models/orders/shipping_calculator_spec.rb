require "rails_helper"

RSpec.describe Orders::ShippingCalculator do
  describe "#initialize" do
    it "uses default values when not specified" do
      calculator = Orders::ShippingCalculator.new
      expect(calculator.free_threshold).to eq(Orders::Money.new(50.00))
      expect(calculator.standard_cost).to eq(Orders::Money.new(5.99))
    end

    it "accepts custom free threshold" do
      calculator = Orders::ShippingCalculator.new(free_threshold: Orders::Money.new(75.00))
      expect(calculator.free_threshold).to eq(Orders::Money.new(75.00))
    end

    it "accepts custom standard cost" do
      calculator = Orders::ShippingCalculator.new(standard_cost: Orders::Money.new(9.99))
      expect(calculator.standard_cost).to eq(Orders::Money.new(9.99))
    end

    it "raises error if free threshold is not Money" do
      expect {
        Orders::ShippingCalculator.new(free_threshold: 50.00)
      }.to raise_error(ArgumentError, /must be a Money object/)
    end

    it "raises error if standard cost is not Money" do
      expect {
        Orders::ShippingCalculator.new(standard_cost: 5.99)
      }.to raise_error(ArgumentError, /must be a Money object/)
    end

    it "raises error for negative shipping cost" do
      expect {
        Orders::ShippingCalculator.new(standard_cost: Orders::Money.new(-5.99))
      }.to raise_error(ArgumentError, /cannot be negative/)
    end

    it "accepts zero shipping cost" do
      calculator = Orders::ShippingCalculator.new(standard_cost: Orders::Money.new(0))
      expect(calculator.standard_cost).to eq(Orders::Money.new(0))
    end
  end

  describe "#calculate" do
    let(:calculator) { Orders::ShippingCalculator.new }

    context "when order is under $50" do
      it "returns standard shipping cost" do
        amount = Orders::Money.new(49.99)
        cost = calculator.calculate(amount)

        expect(cost).to eq(Orders::Money.new(5.99))
      end

      it "works for small amounts" do
        amount = Orders::Money.new(10.00)
        cost = calculator.calculate(amount)

        expect(cost).to eq(Orders::Money.new(5.99))
      end
    end

    context "when order is exactly $50" do
      it "returns free shipping" do
        amount = Orders::Money.new(50.00)
        cost = calculator.calculate(amount)

        expect(cost).to eq(Orders::Money.new(0.00))
      end
    end

    context "when order is over $50" do
      it "returns free shipping" do
        amount = Orders::Money.new(75.00)
        cost = calculator.calculate(amount)

        expect(cost).to eq(Orders::Money.new(0.00))
      end

      it "works for large amounts" do
        amount = Orders::Money.new(500.00)
        cost = calculator.calculate(amount)

        expect(cost).to eq(Orders::Money.new(0.00))
      end
    end

    it "preserves currency of input" do
      amount = Orders::Money.new(30.00, currency: "EUR")
      cost = calculator.calculate(amount)

      expect(cost.currency).to eq("EUR")
    end

    it "raises error for non-Money argument" do
      expect { calculator.calculate(49.99) }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe "#qualifies_for_free_shipping?" do
    let(:calculator) { Orders::ShippingCalculator.new }

    it "returns false for amounts under threshold" do
      amount = Orders::Money.new(49.99)
      expect(calculator.qualifies_for_free_shipping?(amount)).to be_falsey
    end

    it "returns true for amount equal to threshold" do
      amount = Orders::Money.new(50.00)
      expect(calculator.qualifies_for_free_shipping?(amount)).to be_truthy
    end

    it "returns true for amounts over threshold" do
      amount = Orders::Money.new(75.00)
      expect(calculator.qualifies_for_free_shipping?(amount)).to be_truthy
    end

    it "raises error for non-Money argument" do
      expect {
        calculator.qualifies_for_free_shipping?(49.99)
      }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe "#remaining_for_free_shipping" do
    let(:calculator) { Orders::ShippingCalculator.new }

    it "returns amount needed when under threshold" do
      amount = Orders::Money.new(30.00)
      remaining = calculator.remaining_for_free_shipping(amount)

      expect(remaining).to eq(Orders::Money.new(20.00))
    end

    it "returns small amount when close to threshold" do
      amount = Orders::Money.new(49.99)
      remaining = calculator.remaining_for_free_shipping(amount)

      expect(remaining.amount).to be_within(0.01).of(0.01)
    end

    it "returns nil when already qualifies" do
      amount = Orders::Money.new(50.00)
      remaining = calculator.remaining_for_free_shipping(amount)

      expect(remaining).to be_nil
    end

    it "returns nil when over threshold" do
      amount = Orders::Money.new(75.00)
      remaining = calculator.remaining_for_free_shipping(amount)

      expect(remaining).to be_nil
    end

    it "raises error for non-Money argument" do
      expect {
        calculator.remaining_for_free_shipping(30.00)
      }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe ".calculate" do
    it "calculates shipping using class method with defaults" do
      amount = Orders::Money.new(30.00)
      cost = Orders::ShippingCalculator.calculate(amount)

      expect(cost).to eq(Orders::Money.new(5.99))
    end

    it "returns free shipping for qualifying amounts" do
      amount = Orders::Money.new(75.00)
      cost = Orders::ShippingCalculator.calculate(amount)

      expect(cost).to eq(Orders::Money.new(0.00))
    end
  end

  describe "custom configurations" do
    it "works with different threshold" do
      calculator = Orders::ShippingCalculator.new(
        free_threshold: Orders::Money.new(100.00),
        standard_cost: Orders::Money.new(9.99)
      )

      expect(calculator.calculate(Orders::Money.new(99.99))).to eq(Orders::Money.new(9.99))
      expect(calculator.calculate(Orders::Money.new(100.00))).to eq(Orders::Money.new(0.00))
    end

    it "supports premium shipping tiers" do
      premium_calculator = Orders::ShippingCalculator.new(
        free_threshold: Orders::Money.new(75.00),
        standard_cost: Orders::Money.new(12.99)
      )

      expect(premium_calculator.calculate(Orders::Money.new(50.00))).to eq(Orders::Money.new(12.99))
      expect(premium_calculator.calculate(Orders::Money.new(75.00))).to eq(Orders::Money.new(0.00))
    end
  end

  describe "real-world scenarios" do
    let(:calculator) { Orders::ShippingCalculator.new }

    it "handles typical coffee shop order under threshold" do
      order_amount = Orders::Money.new(31.47)
      cost = calculator.calculate(order_amount)

      expect(cost).to eq(Orders::Money.new(5.99))
    end

    it "encourages upselling with remaining calculation" do
      order_amount = Orders::Money.new(45.00)
      remaining = calculator.remaining_for_free_shipping(order_amount)

      expect(remaining).to eq(Orders::Money.new(5.00))
      # Could display: "Add $5.00 more to get free shipping!"
    end

    it "handles edge case just below threshold" do
      order_amount = Orders::Money.new(49.99)
      cost = calculator.calculate(order_amount)

      expect(cost).to eq(Orders::Money.new(5.99))

      remaining = calculator.remaining_for_free_shipping(order_amount)
      expect(remaining.amount).to be_within(0.01).of(0.01)
    end
  end
end
