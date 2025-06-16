require "rails_helper"

RSpec.describe Orders::TaxCalculator do
  describe "#initialize" do
    it "uses default rate when not specified" do
      calculator = Orders::TaxCalculator.new
      expect(calculator.rate).to eq(0.09)
    end

    it "accepts custom tax rate" do
      calculator = Orders::TaxCalculator.new(rate: 0.15)
      expect(calculator.rate).to eq(0.15)
    end

    it "raises error for negative rate" do
      expect { Orders::TaxCalculator.new(rate: -0.1) }.to raise_error(ArgumentError, /between 0 and 1/)
    end

    it "raises error for rate greater than 1" do
      expect { Orders::TaxCalculator.new(rate: 1.5) }.to raise_error(ArgumentError, /between 0 and 1/)
    end

    it "accepts zero rate" do
      calculator = Orders::TaxCalculator.new(rate: 0)
      expect(calculator.rate).to eq(0)
    end

    it "accepts 100% rate" do
      calculator = Orders::TaxCalculator.new(rate: 1.0)
      expect(calculator.rate).to eq(1.0)
    end
  end

  describe "#calculate" do
    let(:calculator) { Orders::TaxCalculator.new(rate: 0.09) }

    it "calculates tax correctly" do
      amount = Orders::Money.new(100.00)
      tax = calculator.calculate(amount)

      expect(tax).to be_a(Orders::Money)
      expect(tax.amount).to eq(9.00)
    end

    it "handles decimal amounts" do
      amount = Orders::Money.new(12.50)
      tax = calculator.calculate(amount)

      expect(tax.cents).to eq(113) # $1.13 rounded
    end

    it "returns zero tax for zero amount" do
      amount = Orders::Money.new(0)
      tax = calculator.calculate(amount)

      expect(tax.amount).to eq(0.00)
    end

    it "calculates with custom rate" do
      custom_calculator = Orders::TaxCalculator.new(rate: 0.15)
      amount = Orders::Money.new(100.00)
      tax = custom_calculator.calculate(amount)

      expect(tax.amount).to eq(15.00)
    end

    it "preserves currency of input" do
      amount = Orders::Money.new(100.00, currency: "EUR")
      tax = calculator.calculate(amount)

      expect(tax.currency).to eq("EUR")
    end

    it "raises error for non-Money argument" do
      expect { calculator.calculate(100) }.to raise_error(ArgumentError, /must be a Money object/)
    end
  end

  describe "#calculate_total" do
    let(:calculator) { Orders::TaxCalculator.new(rate: 0.09) }

    it "returns amount plus tax" do
      amount = Orders::Money.new(100.00)
      total = calculator.calculate_total(amount)

      expect(total.amount).to eq(109.00)
    end

    it "handles decimal amounts" do
      amount = Orders::Money.new(12.50)
      total = calculator.calculate_total(amount)

      expect(total.amount).to eq(13.63) # 12.50 + 1.13
    end
  end

  describe "#percentage" do
    it "returns rate as percentage" do
      calculator = Orders::TaxCalculator.new(rate: 0.09)
      expect(calculator.percentage).to eq(9.0)
    end

    it "works for different rates" do
      calculator = Orders::TaxCalculator.new(rate: 0.15)
      expect(calculator.percentage).to eq(15.0)
    end

    it "works for zero rate" do
      calculator = Orders::TaxCalculator.new(rate: 0)
      expect(calculator.percentage).to eq(0.0)
    end
  end

  describe ".calculate" do
    it "calculates tax using class method with default rate" do
      amount = Orders::Money.new(100.00)
      tax = Orders::TaxCalculator.calculate(amount)

      expect(tax.amount).to eq(9.00)
    end

    it "accepts custom rate" do
      amount = Orders::Money.new(100.00)
      tax = Orders::TaxCalculator.calculate(amount, rate: 0.15)

      expect(tax.amount).to eq(15.00)
    end
  end

  describe "real-world scenarios" do
    let(:calculator) { Orders::TaxCalculator.new }

    it "calculates tax on typical coffee order" do
      order_amount = Orders::Money.new(31.47) # Example from coffee shop
      tax = calculator.calculate(order_amount)

      expect(tax.amount).to be_within(0.01).of(2.83) # 9% of 31.47
    end

    it "handles large order amounts" do
      order_amount = Orders::Money.new(1000.00)
      tax = calculator.calculate(order_amount)

      expect(tax.amount).to eq(90.00)
    end

    it "handles small amounts" do
      order_amount = Orders::Money.new(0.50)
      tax = calculator.calculate(order_amount)

      expect(tax.amount).to be_within(0.01).of(0.05)
    end
  end
end
