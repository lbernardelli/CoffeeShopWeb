require "rails_helper"

RSpec.describe Orders::Money do
  describe "#initialize" do
    it "creates money from dollar amount" do
      money = Orders::Money.new(10.50)
      expect(money.amount).to eq(10.50)
      expect(money.cents).to eq(1050)
      expect(money.currency).to eq("USD")
    end

    it "accepts custom currency" do
      money = Orders::Money.new(10.50, currency: "EUR")
      expect(money.currency).to eq("EUR")
    end

    it "handles zero amount" do
      money = Orders::Money.new(0)
      expect(money.amount).to eq(0.0)
      expect(money.cents).to eq(0)
    end

    it "rounds to nearest cent" do
      money = Orders::Money.new(10.556)
      expect(money.cents).to eq(1056)
    end
  end

  describe ".from_cents" do
    it "creates money from cents" do
      money = Orders::Money.from_cents(1050)
      expect(money.amount).to eq(10.50)
      expect(money.cents).to eq(1050)
    end

    it "accepts custom currency" do
      money = Orders::Money.from_cents(1050, currency: "GBP")
      expect(money.currency).to eq("GBP")
    end
  end

  describe "arithmetic operations" do
    let(:money1) { Orders::Money.new(10.00) }
    let(:money2) { Orders::Money.new(5.50) }

    describe "#+" do
      it "adds two money amounts" do
        result = money1 + money2
        expect(result.amount).to eq(15.50)
        expect(result.currency).to eq("USD")
      end

      it "raises error for different currencies" do
        money_eur = Orders::Money.new(10.00, currency: "EUR")
        expect { money1 + money_eur }.to raise_error(ArgumentError, /different currencies/)
      end
    end

    describe "#-" do
      it "subtracts two money amounts" do
        result = money1 - money2
        expect(result.amount).to eq(4.50)
      end

      it "can result in negative amount" do
        result = money2 - money1
        expect(result.amount).to eq(-4.50)
      end

      it "raises error for different currencies" do
        money_eur = Orders::Money.new(10.00, currency: "EUR")
        expect { money1 - money_eur }.to raise_error(ArgumentError, /different currencies/)
      end
    end

    describe "#*" do
      it "multiplies by a number" do
        result = money1 * 2
        expect(result.amount).to eq(20.00)
      end

      it "handles decimal multipliers" do
        result = money1 * 0.5
        expect(result.amount).to eq(5.00)
      end

      it "rounds to nearest cent" do
        result = Orders::Money.new(10.00) * 0.333
        expect(result.cents).to eq(333)
      end
    end

    describe "#/" do
      it "divides by a number" do
        result = money1 / 2
        expect(result.amount).to eq(5.00)
      end

      it "rounds to nearest cent" do
        result = Orders::Money.new(10.00) / 3
        expect(result.cents).to eq(333)
      end
    end
  end

  describe "comparison operations" do
    let(:money1) { Orders::Money.new(10.00) }
    let(:money2) { Orders::Money.new(5.00) }
    let(:money3) { Orders::Money.new(10.00) }

    it "compares amounts with >" do
      expect(money1 > money2).to be_truthy
      expect(money2 > money1).to be_falsey
    end

    it "compares amounts with <" do
      expect(money2 < money1).to be_truthy
      expect(money1 < money2).to be_falsey
    end

    it "compares amounts with >=" do
      expect(money1 >= money3).to be_truthy
      expect(money1 >= money2).to be_truthy
    end

    it "compares amounts with <=" do
      expect(money1 <= money3).to be_truthy
      expect(money2 <= money1).to be_truthy
    end

    it "checks equality with ==" do
      expect(money1 == money3).to be_truthy
      expect(money1 == money2).to be_falsey
    end

    it "considers currency in equality" do
      money_eur = Orders::Money.new(10.00, currency: "EUR")
      expect(money1 == money_eur).to be_falsey
    end
  end


  describe "formatting" do
    describe "#format" do
      it "formats USD with symbol by default" do
        money = Orders::Money.new(1234.56)
        expect(money.format).to eq("$1,234.56")
      end

      it "formats without symbol when specified" do
        money = Orders::Money.new(1234.56)
        expect(money.format(symbol: false)).to eq("1,234.56")
      end

      it "formats EUR with correct symbol" do
        money = Orders::Money.new(1234.56, currency: "EUR")
        expect(money.format).to eq("€1,234.56")
      end

      it "formats GBP with correct symbol" do
        money = Orders::Money.new(1234.56, currency: "GBP")
        expect(money.format).to eq("£1,234.56")
      end

      it "formats BRL with correct symbol" do
        money = Orders::Money.new(1234.56, currency: "BRL")
        expect(money.format).to eq("R$1,234.56")
      end

      it "uses currency code for unknown currencies" do
        money = Orders::Money.new(1234.56, currency: "CAD")
        expect(money.format).to eq("CAD1,234.56")
      end

      it "formats zero amount" do
        money = Orders::Money.new(0)
        expect(money.format).to eq("$0.00")
      end

      it "formats negative amounts" do
        money = Orders::Money.from_cents(-1234)
        expect(money.format).to eq("$-12.34")
      end
    end

    describe "#to_s" do
      it "returns formatted string" do
        money = Orders::Money.new(100.50)
        expect(money.to_s).to eq("$100.50")
      end
    end

    describe "#inspect" do
      it "returns detailed representation" do
        money = Orders::Money.new(100.50)
        expect(money.inspect).to eq("#<Money $100.50 (10050 cents, USD)>")
      end
    end
  end

  describe "#convert_to" do
    it "converts to another currency with given rate" do
      usd = Orders::Money.new(100.00, currency: "USD")
      eur = usd.convert_to("EUR", rate: 0.85)

      expect(eur.currency).to eq("EUR")
      expect(eur.amount).to eq(85.00)
    end

    it "handles fractional conversion rates" do
      usd = Orders::Money.new(100.00, currency: "USD")
      jpy = usd.convert_to("JPY", rate: 110.5)

      expect(jpy.currency).to eq("JPY")
      expect(jpy.amount).to eq(11050.00)
    end
  end

  describe "type conversions" do
    let(:money) { Orders::Money.new(10.50) }

    describe "#to_f" do
      it "returns amount as float" do
        expect(money.to_f).to eq(10.50)
        expect(money.to_f).to be_a(Float)
      end
    end

    describe "#to_i" do
      it "returns cents as integer" do
        expect(money.to_i).to eq(1050)
        expect(money.to_i).to be_a(Integer)
      end
    end

    describe "#to_d" do
      it "returns amount as BigDecimal" do
        expect(money.to_d).to eq(BigDecimal("10.50"))
        expect(money.to_d).to be_a(BigDecimal)
      end
    end
  end
end
