class Orders::ShippingCalculator
  FREE_SHIPPING_THRESHOLD = Orders::Money.new(50.00)
  STANDARD_SHIPPING_COST = Orders::Money.new(5.99)

  attr_reader :free_threshold, :standard_cost

  # @param free_threshold [Money] Minimum order amount for free shipping
  # @param standard_cost [Money] Standard shipping cost
  def initialize(free_threshold: FREE_SHIPPING_THRESHOLD, standard_cost: STANDARD_SHIPPING_COST)
    @free_threshold = free_threshold
    @standard_cost = standard_cost
    validate_amounts!
  end

  # Calculate shipping cost for a given order amount
  # @param amount [Money] The order subtotal
  # @return [Money] The shipping cost (may be zero for free shipping)
  def calculate(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    if qualifies_for_free_shipping?(amount)
      Orders::Money.new(0, currency: amount.currency)
    else
      # Return standard cost in the same currency as the amount
      Orders::Money.new(standard_cost.to_f, currency: amount.currency)
    end
  end

  # Check if an amount qualifies for free shipping
  # @param amount [Money] The order subtotal
  # @return [Boolean]
  def qualifies_for_free_shipping?(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    amount.to_f >= free_threshold.to_f
  end

  # Calculate remaining amount needed for free shipping
  # @param amount [Money] The current order subtotal
  # @return [Money, nil] Amount needed for free shipping, or nil if already qualifies
  def remaining_for_free_shipping(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    return nil if qualifies_for_free_shipping?(amount)

    Orders::Money.new(free_threshold.to_f - amount.to_f, currency: amount.currency)
  end

  # Class method for quick calculation with defaults
  # @param amount [Money] The amount to calculate shipping for
  # @return [Money] The shipping cost
  def self.calculate(amount)
    new.calculate(amount)
  end

  private

  def validate_amounts!
    unless free_threshold.is_a?(Orders::Money)
      raise ArgumentError, "Free shipping threshold must be a Money object"
    end

    unless standard_cost.is_a?(Orders::Money)
      raise ArgumentError, "Standard shipping cost must be a Money object"
    end

    if standard_cost < Orders::Money.new(0)
      raise ArgumentError, "Standard shipping cost cannot be negative"
    end
  end
end
