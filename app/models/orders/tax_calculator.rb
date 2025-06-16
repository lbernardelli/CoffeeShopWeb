# Service object for calculating taxes on monetary amounts
class Orders::TaxCalculator
  DEFAULT_RATE = 0.09 # 9% tax rate

  attr_reader :rate

  # @param rate [Float] The tax rate (e.g., 0.09 for 9%)
  def initialize(rate: DEFAULT_RATE)
    @rate = rate
    validate_rate!
  end

  # Calculate tax for a given amount
  # @param amount [Money] The amount to calculate tax on
  # @return [Money] The tax amount
  def calculate(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    amount * rate
  end

  # Calculate total including tax
  # @param amount [Money] The pre-tax amount
  # @return [Money] The total with tax included
  def calculate_total(amount)
    amount + calculate(amount)
  end

  # Get tax rate as percentage
  # @return [Float] The tax rate as a percentage (e.g., 9.0 for 9%)
  def percentage
    rate * 100
  end

  # Class method for quick calculation with default rate
  # @param amount [Money] The amount to calculate tax on
  # @param rate [Float] Optional custom rate
  # @return [Money] The tax amount
  def self.calculate(amount, rate: DEFAULT_RATE)
    new(rate: rate).calculate(amount)
  end

  private

  def validate_rate!
    unless rate.is_a?(Numeric) && rate >= 0 && rate <= 1
      raise ArgumentError, "Tax rate must be a number between 0 and 1"
    end
  end
end
