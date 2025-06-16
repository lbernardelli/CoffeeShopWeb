class Orders::PromotionalShippingCalculator < Orders::ShippingCalculator
  attr_reader :promotion_name, :start_date, :end_date, :promotional_threshold, :promotional_cost

  # @param promotion_name [String] Name of the promotion
  # @param start_date [Date] Promotion start date
  # @param end_date [Date] Promotion end date
  # @param promotional_threshold [Money] Free shipping threshold during promotion
  # @param promotional_cost [Money] Shipping cost during promotion (if not free)
  # @param free_threshold [Money] Standard free shipping threshold
  # @param standard_cost [Money] Standard shipping cost
  def initialize(
    promotion_name:,
    start_date:,
    end_date:,
    promotional_threshold: Orders::Money.new(0),
    promotional_cost: Orders::Money.new(0),
    free_threshold: FREE_SHIPPING_THRESHOLD,
    standard_cost: STANDARD_SHIPPING_COST
  )
    super(free_threshold: free_threshold, standard_cost: standard_cost)
    @promotion_name = promotion_name
    @start_date = start_date
    @end_date = end_date
    @promotional_threshold = promotional_threshold
    @promotional_cost = promotional_cost
    validate_promotion!
  end

  # Calculate shipping cost based on promotion status
  # @param amount [Money] The order subtotal
  # @param date [Date] The date to check (defaults to today)
  # @return [Money] The shipping cost
  def calculate(amount, date: Date.today)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    if promotion_active?(date)
      calculate_promotional_shipping(amount)
    else
      super(amount)
    end
  end

  # Check if promotion is currently active
  # @param date [Date] The date to check (defaults to today)
  # @return [Boolean]
  def promotion_active?(date = Date.today)
    date >= start_date && date <= end_date
  end

  # Get promotional discount amount
  # @param amount [Money] The order subtotal
  # @param date [Date] The date to check
  # @return [Money] The discount amount on shipping
  def shipping_discount(amount, date: Date.today)
    return Orders::Money.new(0, currency: amount.currency) unless promotion_active?(date)

    # Calculate standard shipping using parent class logic
    standard_shipping = Orders::ShippingCalculator.new(
      free_threshold: free_threshold,
      standard_cost: standard_cost
    ).calculate(amount)
    promotional_shipping = calculate_promotional_shipping(amount)
    standard_shipping - promotional_shipping
  end

  private

  def calculate_promotional_shipping(amount)
    # Convert to same currency for comparison
    threshold_amount = promotional_threshold.to_f
    if amount.to_f >= threshold_amount
      Orders::Money.new(0, currency: amount.currency)
    else
      Orders::Money.new(promotional_cost.to_f, currency: amount.currency)
    end
  end

  def validate_promotion!
    unless promotion_name.present?
      raise ArgumentError, "Promotion name cannot be blank"
    end

    unless promotional_threshold.is_a?(Orders::Money)
      raise ArgumentError, "Promotional threshold must be a Money object"
    end

    unless promotional_cost.is_a?(Orders::Money)
      raise ArgumentError, "Promotional cost must be a Money object"
    end

    if start_date > end_date
      raise ArgumentError, "Start date must be before end date"
    end

    if promotional_cost < Orders::Money.new(0)
      raise ArgumentError, "Promotional shipping cost cannot be negative"
    end
  end
end
