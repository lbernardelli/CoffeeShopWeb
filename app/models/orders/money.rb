class Orders::Money
  include Comparable

  attr_reader :cents, :currency

  # @param amount [Numeric] The amount in the base unit (dollars, euros, etc.)
  # @param currency [String] The ISO currency code (default: USD)
  def initialize(amount, currency: "USD")
    @cents = (amount.to_f * 100).round
    @currency = currency.to_s.upcase
  end

  # Create Money from cents
  # @param cents [Integer] The amount in cents
  # @param currency [String] The ISO currency code
  # @return [Money]
  def self.from_cents(cents, currency: "USD")
    money = allocate
    money.instance_variable_set(:@cents, cents.to_i)
    money.instance_variable_set(:@currency, currency.to_s.upcase)
    money
  end

  # @return [Float] The amount in the base unit
  def amount
    cents / 100.0
  end

  # @return [BigDecimal] The amount as BigDecimal for precision
  def to_d
    BigDecimal(cents) / 100
  end

  # @return [Float] Alias for amount
  def to_f
    amount
  end

  # @return [Integer]
  def to_i
    cents
  end

  # Arithmetic operations
  def +(other)
    ensure_same_currency!(other)
    self.class.from_cents(cents + other.cents, currency: currency)
  end

  def -(other)
    ensure_same_currency!(other)
    self.class.from_cents(cents - other.cents, currency: currency)
  end

  def *(multiplier)
    self.class.from_cents((cents * multiplier).round, currency: currency)
  end

  def /(divisor)
    self.class.from_cents((cents / divisor).round, currency: currency)
  end

  # Comparison
  def <=>(other)
    return nil unless other.is_a?(Orders::Money)
    ensure_same_currency!(other)
    cents <=> other.cents
  end

  def ==(other)
    other.is_a?(Orders::Money) && cents == other.cents && currency == other.currency
  end

  # Format as currency string
  # @param options [Hash] Formatting options
  # @option options [Boolean] :symbol Whether to include currency symbol
  # @option options [String] :separator Decimal separator
  # @option options [String] :delimiter Thousands delimiter
  # @return [String]
  def format(symbol: true, separator: ".", delimiter: ",")
    formatted_amount = sprintf("%.2f", amount)
    parts = formatted_amount.split(".")
    parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{delimiter}")
    formatted = parts.join(separator)

    if symbol
      "#{currency_symbol}#{formatted}"
    else
      formatted
    end
  end

  # @return [String]
  def to_s
    format
  end

  # @return [String]
  def inspect
    "#<Money #{format} (#{cents} cents, #{currency})>"
  end

  # Currency conversion
  # @param target_currency [String] The target currency code
  # @param rate [Float] The conversion rate
  # @return [Money]
  def convert_to(target_currency, rate:)
    new_cents = (cents * rate).round
    self.class.from_cents(new_cents, currency: target_currency)
  end

  private

  def ensure_same_currency!(other)
    unless other.is_a?(Orders::Money) && other.currency == currency
      raise ArgumentError, "Cannot perform operation on different currencies: #{currency} vs #{other&.currency}"
    end
  end

  def currency_symbol
    case currency
    when "USD" then "$"
    when "EUR" then "€"
    when "GBP" then "£"
    when "JPY" then "¥"
    when "BRL" then "R$"
    else currency
    end
  end
end
