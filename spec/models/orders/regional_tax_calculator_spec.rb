require "rails_helper"

RSpec.describe Orders::RegionalTaxCalculator do
  describe "#initialize" do
    it "initializes with state tax rate" do
      calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
      expect(calculator.region).to eq("CA")
      expect(calculator.rate).to eq(0.0725) # California rate
    end

    it "initializes with country tax rate" do
      calculator = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
      expect(calculator.region).to eq("GB")
      expect(calculator.rate).to eq(0.20) # UK VAT
    end

    it "uses fallback rate for unknown region" do
      calculator = Orders::RegionalTaxCalculator.new(
        region: "XX",
        region_type: :state,
        fallback_rate: 0.05
      )
      expect(calculator.rate).to eq(0.05)
    end

    it "converts region to uppercase" do
      calculator = Orders::RegionalTaxCalculator.new(region: "ca", region_type: :state)
      expect(calculator.region).to eq("CA")
    end
  end

  describe "#calculate" do
    context "with state tax rates" do
      it "calculates California tax" do
        calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(7.25)
      end

      it "calculates Texas tax" do
        calculator = Orders::RegionalTaxCalculator.new(region: "TX", region_type: :state)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(6.25)
      end

      it "returns zero tax for Alaska (no state tax)" do
        calculator = Orders::RegionalTaxCalculator.new(region: "AK", region_type: :state)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(0.00)
      end

      it "calculates Florida tax" do
        calculator = Orders::RegionalTaxCalculator.new(region: "FL", region_type: :state)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(6.00)
      end
    end

    context "with country tax rates" do
      it "calculates UK VAT" do
        calculator = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(20.00)
      end

      it "calculates German VAT" do
        calculator = Orders::RegionalTaxCalculator.new(region: "DE", region_type: :country)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(19.00)
      end

      it "calculates Canada GST" do
        calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :country)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(5.00)
      end

      it "calculates Australia GST" do
        calculator = Orders::RegionalTaxCalculator.new(region: "AU", region_type: :country)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(10.00)
      end

      it "calculates Japan consumption tax" do
        calculator = Orders::RegionalTaxCalculator.new(region: "JP", region_type: :country)
        amount = Orders::Money.new(100.00)
        tax = calculator.calculate(amount)

        expect(tax.amount).to eq(10.00)
      end
    end

    it "preserves currency" do
      calculator = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
      amount = Orders::Money.new(100.00, currency: "GBP")
      tax = calculator.calculate(amount)

      expect(tax.currency).to eq("GBP")
    end

    it "raises error for non-Money amount" do
      calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
      expect {
        calculator.calculate(100.00)
      }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe "#tax_name" do
    it "returns state sales tax name" do
      calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
      expect(calculator.tax_name).to eq("CA State Sales Tax")
    end

    it "returns VAT for UK" do
      calculator = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
      expect(calculator.tax_name).to eq("VAT")
    end

    it "returns GST for Canada" do
      calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :country)
      expect(calculator.tax_name).to eq("GST")
    end

    it "returns Consumption Tax for Japan" do
      calculator = Orders::RegionalTaxCalculator.new(region: "JP", region_type: :country)
      expect(calculator.tax_name).to eq("Consumption Tax")
    end
  end

  describe "#tax_exempt?" do
    it "returns true for Alaska" do
      calculator = Orders::RegionalTaxCalculator.new(region: "AK", region_type: :state)
      expect(calculator.tax_exempt?(Orders::Money.new(100.00))).to be_truthy
    end

    it "returns false for other states" do
      calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
      expect(calculator.tax_exempt?(Orders::Money.new(100.00))).to be_falsey
    end
  end

  describe "real-world scenarios" do
    it "handles multi-state coffee shop" do
      # New York store
      ny_calculator = Orders::RegionalTaxCalculator.new(region: "NY", region_type: :state)
      order_amount = Orders::Money.new(31.47)
      ny_tax = ny_calculator.calculate(order_amount)

      expect(ny_tax.amount).to be_within(0.01).of(1.26) # 4% of 31.47

      # California store
      ca_calculator = Orders::RegionalTaxCalculator.new(region: "CA", region_type: :state)
      ca_tax = ca_calculator.calculate(order_amount)

      expect(ca_tax.amount).to be_within(0.01).of(2.28) # 7.25% of 31.47
    end

    it "handles international expansion" do
      order_amount = Orders::Money.new(50.00)

      # US store
      us_calculator = Orders::RegionalTaxCalculator.new(region: "US", region_type: :country)
      us_tax = us_calculator.calculate(order_amount)
      expect(us_tax.amount).to eq(4.50) # 9%

      # UK store
      uk_calculator = Orders::RegionalTaxCalculator.new(region: "GB", region_type: :country)
      uk_tax = uk_calculator.calculate(order_amount)
      expect(uk_tax.amount).to eq(10.00) # 20% VAT
    end
  end
end
