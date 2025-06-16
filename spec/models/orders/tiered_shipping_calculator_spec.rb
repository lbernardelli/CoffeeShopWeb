require "rails_helper"

RSpec.describe Orders::TieredShippingCalculator do
  describe Orders::TieredShippingCalculator::ShippingTier do
    describe "#initialize" do
      it "creates a valid tier" do
        tier = Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Standard",
          cost: Orders::Money.new(5.99),
          free_threshold: Orders::Money.new(50.00),
          delivery_days: 5,
          cutoff_time: "17:00"
        )

        expect(tier.name).to eq("Standard")
        expect(tier.cost).to eq(Orders::Money.new(5.99))
        expect(tier.delivery_days).to eq(5)
      end

      it "raises error for blank name" do
        expect {
          Orders::TieredShippingCalculator::ShippingTier.new(
            name: "",
            cost: Orders::Money.new(5.99),
            delivery_days: 5
          )
        }.to raise_error(ArgumentError, /cannot be blank/)
      end

      it "raises error for non-Money cost" do
        expect {
          Orders::TieredShippingCalculator::ShippingTier.new(
            name: "Standard",
            cost: 5.99,
            delivery_days: 5
          )
        }.to raise_error(ArgumentError, /must be a Money object/)
      end

      it "allows zero delivery days for same-day" do
        tier = Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Same Day",
          cost: Orders::Money.new(49.99),
          delivery_days: 0
        )
        expect(tier.delivery_days).to eq(0)
      end
    end

    describe "#qualifies_for_free_shipping?" do
      let(:tier) do
        Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Standard",
          cost: Orders::Money.new(5.99),
          free_threshold: Orders::Money.new(50.00),
          delivery_days: 5
        )
      end

      it "returns true when amount meets threshold" do
        expect(tier.qualifies_for_free_shipping?(Orders::Money.new(50.00))).to be_truthy
      end

      it "returns false when amount is below threshold" do
        expect(tier.qualifies_for_free_shipping?(Orders::Money.new(49.99))).to be_falsey
      end

      it "returns false when no threshold is set" do
        no_free_tier = Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Overnight",
          cost: Orders::Money.new(24.99),
          free_threshold: nil,
          delivery_days: 1
        )

        expect(no_free_tier.qualifies_for_free_shipping?(Orders::Money.new(100.00))).to be_falsey
      end
    end

    describe "#calculate_cost" do
      let(:tier) do
        Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Standard",
          cost: Orders::Money.new(5.99),
          free_threshold: Orders::Money.new(50.00),
          delivery_days: 5
        )
      end

      it "returns zero when free shipping threshold met" do
        cost = tier.calculate_cost(Orders::Money.new(50.00))
        expect(cost).to eq(Orders::Money.new(0.00))
      end

      it "returns tier cost when below threshold" do
        cost = tier.calculate_cost(Orders::Money.new(30.00))
        expect(cost).to eq(Orders::Money.new(5.99))
      end
    end
  end

  describe Orders::TieredShippingCalculator do
    let(:calculator) { Orders::TieredShippingCalculator.new }

    describe "#initialize" do
      it "initializes with default tiers" do
        expect(calculator.tiers.size).to eq(3)
        expect(calculator.tiers.map(&:name)).to include("Standard Shipping", "Express Shipping", "Overnight Shipping")
      end

      it "accepts custom tiers" do
        custom_tier = Orders::TieredShippingCalculator::ShippingTier.new(
          name: "Same Day",
          cost: Orders::Money.new(49.99),
          delivery_days: 0,
          cutoff_time: "10:00"
        )

        custom_calculator = Orders::TieredShippingCalculator.new(tiers: [ custom_tier ])
        expect(custom_calculator.tiers.size).to eq(1)
        expect(custom_calculator.tiers.first.name).to eq("Same Day")
      end

      it "raises error with no tiers" do
        expect {
          Orders::TieredShippingCalculator.new(tiers: [])
        }.to raise_error(ArgumentError, /at least one tier/)
      end
    end

    describe "#calculate" do
      it "calculates standard shipping cost" do
        amount = Orders::Money.new(30.00)
        cost = calculator.calculate(amount, tier_name: "Standard Shipping")

        expect(cost).to eq(Orders::Money.new(5.99))
      end

      it "calculates express shipping cost" do
        amount = Orders::Money.new(30.00)
        cost = calculator.calculate(amount, tier_name: "Express Shipping")

        expect(cost).to eq(Orders::Money.new(12.99))
      end

      it "calculates overnight shipping cost" do
        amount = Orders::Money.new(30.00)
        cost = calculator.calculate(amount, tier_name: "Overnight Shipping")

        expect(cost).to eq(Orders::Money.new(24.99))
      end

      it "applies free standard shipping over threshold" do
        amount = Orders::Money.new(75.00)
        cost = calculator.calculate(amount, tier_name: "Standard Shipping")

        expect(cost).to eq(Orders::Money.new(0.00))
      end

      it "applies free express shipping over higher threshold" do
        amount = Orders::Money.new(150.00)
        cost = calculator.calculate(amount, tier_name: "Express Shipping")

        expect(cost).to eq(Orders::Money.new(0.00))
      end

      it "never applies free overnight shipping" do
        amount = Orders::Money.new(1000.00)
        cost = calculator.calculate(amount, tier_name: "Overnight Shipping")

        expect(cost).to eq(Orders::Money.new(24.99))
      end

      it "raises error for unknown tier" do
        expect {
          calculator.calculate(Orders::Money.new(30.00), tier_name: "Unknown Tier")
        }.to raise_error(ArgumentError, /not found/)
      end

      it "raises error for non-Money amount" do
        expect {
          calculator.calculate(30.00, tier_name: "Standard Shipping")
        }.to raise_error(ArgumentError, /must be a Money object/)
      end
    end

    describe "#available_tiers" do
      it "returns all tiers with calculated costs" do
        amount = Orders::Money.new(30.00)
        tiers = calculator.available_tiers(amount)

        expect(tiers.size).to eq(3)
        expect(tiers[0][:name]).to eq("Standard Shipping")
        expect(tiers[0][:cost]).to eq(Orders::Money.new(5.99))
        expect(tiers[0][:delivery_days]).to eq(5)
        expect(tiers[0][:free_shipping]).to be_falsey
      end

      it "shows free shipping for qualifying amounts" do
        amount = Orders::Money.new(75.00)
        tiers = calculator.available_tiers(amount)

        standard = tiers.find { |t| t[:name] == "Standard Shipping" }
        expect(standard[:cost]).to eq(Orders::Money.new(0.00))
        expect(standard[:free_shipping]).to be_truthy
      end

      it "raises error for non-Money amount" do
        expect {
          calculator.available_tiers(30.00)
        }.to raise_error(ArgumentError, /must be a Money object/)
      end
    end

    describe "#estimated_delivery_date" do
      let(:monday_morning) { Time.zone.parse("2025-12-01 10:00:00") } # Monday 10am
      let(:monday_afternoon) { Time.zone.parse("2025-12-01 18:00:00") } # Monday 6pm

      before do
        allow(Time).to receive(:current).and_return(monday_morning)
      end

      it "estimates delivery for standard shipping before cutoff" do
        delivery = calculator.estimated_delivery_date(
          tier_name: "Standard Shipping",
          order_time: monday_morning
        )

        # 5 business days from Monday = next Monday
        expect(delivery).to eq(Date.new(2025, 12, 8))
      end

      it "adds extra day when ordered after cutoff" do
        delivery = calculator.estimated_delivery_date(
          tier_name: "Standard Shipping",
          order_time: monday_afternoon
        )

        # After 5pm cutoff (18:00 > 17:00), adds 1 day
        # Standard is 5 days + 1 extra = 6 days from Monday = Sunday, moved to Monday
        expect(delivery).to eq(Date.new(2025, 12, 8))
      end

      it "estimates express shipping delivery" do
        delivery = calculator.estimated_delivery_date(
          tier_name: "Express Shipping",
          order_time: monday_morning
        )

        # 2 business days from Monday = Wednesday
        expect(delivery).to eq(Date.new(2025, 12, 3))
      end

      it "raises error for unknown tier" do
        expect {
          calculator.estimated_delivery_date(tier_name: "Unknown Tier")
        }.to raise_error(ArgumentError, /not found/)
      end
    end

    describe "#cheapest_tier" do
      it "returns standard tier for amounts under $50" do
        amount = Orders::Money.new(30.00)
        cheapest = calculator.cheapest_tier(amount)

        expect(cheapest.name).to eq("Standard Shipping")
      end

      it "returns free standard tier when over threshold" do
        amount = Orders::Money.new(75.00)
        cheapest = calculator.cheapest_tier(amount)

        expect(cheapest.name).to eq("Standard Shipping")
        expect(cheapest.calculate_cost(amount)).to eq(Orders::Money.new(0.00))
      end
    end

    describe "#fastest_tier" do
      it "returns overnight tier" do
        fastest = calculator.fastest_tier
        expect(fastest.name).to eq("Overnight Shipping")
        expect(fastest.delivery_days).to eq(1)
      end
    end

    describe "real-world scenarios" do
      it "handles typical order with multiple shipping options" do
        amount = Orders::Money.new(45.00)
        tiers = calculator.available_tiers(amount)

        standard = tiers.find { |t| t[:name] == "Standard Shipping" }
        express = tiers.find { |t| t[:name] == "Express Shipping" }
        overnight = tiers.find { |t| t[:name] == "Overnight Shipping" }

        expect(standard[:cost]).to eq(Orders::Money.new(5.99))
        expect(express[:cost]).to eq(Orders::Money.new(12.99))
        expect(overnight[:cost]).to eq(Orders::Money.new(24.99))

        expect(standard[:delivery_days]).to eq(5)
        expect(express[:delivery_days]).to eq(2)
        expect(overnight[:delivery_days]).to eq(1)
      end

      it "shows free standard shipping upsell opportunity" do
        amount = Orders::Money.new(45.00)
        cost = calculator.calculate(amount, tier_name: "Standard Shipping")

        expect(cost).to eq(Orders::Money.new(5.99))

        # Customer could add $5 to get free shipping
        upgraded_amount = Orders::Money.new(50.00)
        upgraded_cost = calculator.calculate(upgraded_amount, tier_name: "Standard Shipping")

        expect(upgraded_cost).to eq(Orders::Money.new(0.00))
      end
    end
  end
end
