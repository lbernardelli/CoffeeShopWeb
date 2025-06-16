require "rails_helper"

RSpec.describe Orders::PromotionalShippingCalculator do
  let(:start_date) { Date.new(2025, 12, 1) }
  let(:end_date) { Date.new(2025, 12, 31) }

  let(:calculator) do
    Orders::PromotionalShippingCalculator.new(
      promotion_name: "Holiday Free Shipping",
      start_date: start_date,
      end_date: end_date,
      promotional_threshold: Orders::Money.new(25.00),
      promotional_cost: Orders::Money.new(2.99)
    )
  end

  describe "#initialize" do
    it "creates calculator with promotion details" do
      expect(calculator.promotion_name).to eq("Holiday Free Shipping")
      expect(calculator.start_date).to eq(start_date)
      expect(calculator.end_date).to eq(end_date)
    end

    it "raises error for blank promotion name" do
      expect {
        Orders::PromotionalShippingCalculator.new(
          promotion_name: "",
          start_date: start_date,
          end_date: end_date
        )
      }.to raise_error(ArgumentError, /cannot be blank/)
    end

    it "raises error if start date is after end date" do
      expect {
        Orders::PromotionalShippingCalculator.new(
          promotion_name: "Invalid Promo",
          start_date: Date.new(2025, 12, 31),
          end_date: Date.new(2025, 12, 1)
        )
      }.to raise_error(ArgumentError, /before end date/)
    end

    it "accepts zero promotional cost for completely free shipping" do
      free_promo = Orders::PromotionalShippingCalculator.new(
        promotion_name: "Free Shipping Weekend",
        start_date: start_date,
        end_date: end_date,
        promotional_threshold: Orders::Money.new(0),
        promotional_cost: Orders::Money.new(0)
      )

      expect(free_promo.promotional_cost).to eq(Orders::Money.new(0))
    end
  end

  describe "#promotion_active?" do
    it "returns true during promotion period" do
      expect(calculator.promotion_active?(Date.new(2025, 12, 15))).to be_truthy
    end

    it "returns true on start date" do
      expect(calculator.promotion_active?(start_date)).to be_truthy
    end

    it "returns true on end date" do
      expect(calculator.promotion_active?(end_date)).to be_truthy
    end

    it "returns false before promotion" do
      expect(calculator.promotion_active?(Date.new(2025, 11, 30))).to be_falsey
    end

    it "returns false after promotion" do
      expect(calculator.promotion_active?(Date.new(2026, 1, 1))).to be_falsey
    end

    it "defaults to today" do
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 15))
      expect(calculator.promotion_active?).to be_truthy
    end
  end

  describe "#calculate" do
    context "during promotion period" do
      let(:promo_date) { Date.new(2025, 12, 15) }

      it "applies promotional free shipping when threshold met" do
        amount = Orders::Money.new(30.00)
        cost = calculator.calculate(amount, date: promo_date)

        expect(cost).to eq(Orders::Money.new(0.00))
      end

      it "applies promotional cost when under threshold" do
        amount = Orders::Money.new(20.00)
        cost = calculator.calculate(amount, date: promo_date)

        expect(cost).to eq(Orders::Money.new(2.99))
      end

      it "applies promotional cost exactly at threshold" do
        amount = Orders::Money.new(25.00)
        cost = calculator.calculate(amount, date: promo_date)

        expect(cost).to eq(Orders::Money.new(0.00))
      end
    end

    context "outside promotion period" do
      let(:regular_date) { Date.new(2026, 1, 15) }

      it "applies standard shipping rules" do
        amount = Orders::Money.new(49.99)
        cost = calculator.calculate(amount, date: regular_date)

        expect(cost).to eq(Orders::Money.new(5.99))
      end

      it "applies standard free shipping" do
        amount = Orders::Money.new(75.00)
        cost = calculator.calculate(amount, date: regular_date)

        expect(cost).to eq(Orders::Money.new(0.00))
      end
    end

    it "defaults to today's date" do
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 15))
      amount = Orders::Money.new(30.00)
      cost = calculator.calculate(amount)

      expect(cost).to eq(Orders::Money.new(0.00))
    end

    it "preserves currency" do
      amount = Orders::Money.new(30.00, currency: "EUR")
      cost = calculator.calculate(amount, date: Date.new(2025, 12, 15))

      expect(cost.currency).to eq("EUR")
    end

    it "raises error for non-Money amount" do
      expect {
        calculator.calculate(30.00, date: Date.new(2025, 12, 15))
      }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe "#shipping_discount" do
    it "calculates discount during promotion" do
      amount = Orders::Money.new(30.00)
      discount = calculator.shipping_discount(amount, date: Date.new(2025, 12, 15))

      # Standard would be $5.99, promotional is free, so discount is $5.99
      expect(discount).to eq(Orders::Money.new(5.99))
    end

    it "calculates partial discount when promotional cost applies" do
      amount = Orders::Money.new(20.00)
      discount = calculator.shipping_discount(amount, date: Date.new(2025, 12, 15))

      # Standard is $5.99, promotional is $2.99, discount is $3.00
      expect(discount).to eq(Orders::Money.new(3.00))
    end

    it "returns zero discount outside promotion" do
      amount = Orders::Money.new(30.00)
      discount = calculator.shipping_discount(amount, date: Date.new(2026, 1, 15))

      expect(discount).to eq(Orders::Money.new(0.00))
    end

    it "defaults to today's date" do
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 15))
      amount = Orders::Money.new(30.00)
      discount = calculator.shipping_discount(amount)

      expect(discount).to eq(Orders::Money.new(5.99))
    end
  end

  describe "real-world scenarios" do
    it "handles Black Friday promotion" do
      black_friday = Orders::PromotionalShippingCalculator.new(
        promotion_name: "Black Friday",
        start_date: Date.new(2025, 11, 29),
        end_date: Date.new(2025, 11, 29),
        promotional_threshold: Orders::Money.new(0),
        promotional_cost: Orders::Money.new(0)
      )

      amount = Orders::Money.new(10.00)
      cost = black_friday.calculate(amount, date: Date.new(2025, 11, 29))

      expect(cost).to eq(Orders::Money.new(0.00))
    end

    it "handles reduced shipping promotion" do
      amount = Orders::Money.new(30.00)

      # Regular shipping
      regular_cost = calculator.calculate(amount, date: Date.new(2025, 11, 15))
      expect(regular_cost).to eq(Orders::Money.new(5.99))

      # Promotional shipping
      promo_cost = calculator.calculate(amount, date: Date.new(2025, 12, 15))
      expect(promo_cost).to eq(Orders::Money.new(0.00))

      # Savings
      discount = calculator.shipping_discount(amount, date: Date.new(2025, 12, 15))
      expect(discount).to eq(Orders::Money.new(5.99))
    end

    it "encourages customers to meet promotional threshold" do
      # Just under threshold
      amount = Orders::Money.new(24.50)
      cost = calculator.calculate(amount, date: Date.new(2025, 12, 15))
      expect(cost).to eq(Orders::Money.new(2.99))

      # Meet threshold
      upgraded_amount = Orders::Money.new(25.00)
      upgraded_cost = calculator.calculate(upgraded_amount, date: Date.new(2025, 12, 15))
      expect(upgraded_cost).to eq(Orders::Money.new(0.00))

      # Could show: "Add $0.50 to get free shipping!"
    end
  end
end
