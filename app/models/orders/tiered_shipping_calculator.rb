# Service object for calculating tiered shipping costs (standard, express, overnight)
class Orders::TieredShippingCalculator
  # Shipping tier configuration
  class ShippingTier
    attr_reader :name, :cost, :free_threshold, :delivery_days, :cutoff_time

    # @param name [String] Tier name (e.g., "Standard", "Express", "Overnight")
    # @param cost [Money] Base shipping cost
    # @param free_threshold [Money] Threshold for free shipping (nil if never free)
    # @param delivery_days [Integer] Estimated delivery days
    # @param cutoff_time [String] Order cutoff time for same-day processing (e.g., "14:00")
    def initialize(name:, cost:, free_threshold: nil, delivery_days:, cutoff_time: nil)
      @name = name
      @cost = cost
      @free_threshold = free_threshold
      @delivery_days = delivery_days
      @cutoff_time = cutoff_time
      validate!
    end

    def qualifies_for_free_shipping?(amount)
      return false if free_threshold.nil?
      amount >= free_threshold
    end

    def calculate_cost(amount)
      if qualifies_for_free_shipping?(amount)
        Orders::Money.new(0, currency: amount.currency)
      else
        Orders::Money.new(cost.to_f, currency: amount.currency)
      end
    end

    private

    def validate!
      raise ArgumentError, "Tier name cannot be blank" if name.blank?
      raise ArgumentError, "Cost must be a Money object" unless cost.is_a?(Orders::Money)
      raise ArgumentError, "Free threshold must be a Money object or nil" unless free_threshold.nil? || free_threshold.is_a?(Orders::Money)
      raise ArgumentError, "Delivery days must be positive" unless delivery_days >= 0
    end
  end

  # Default shipping tiers
  STANDARD_TIER = ShippingTier.new(
    name: "Standard Shipping",
    cost: Orders::Money.new(5.99),
    free_threshold: Orders::Money.new(50.00),
    delivery_days: 5,
    cutoff_time: "17:00"
  )

  EXPRESS_TIER = ShippingTier.new(
    name: "Express Shipping",
    cost: Orders::Money.new(12.99),
    free_threshold: Orders::Money.new(100.00),
    delivery_days: 2,
    cutoff_time: "14:00"
  )

  OVERNIGHT_TIER = ShippingTier.new(
    name: "Overnight Shipping",
    cost: Orders::Money.new(24.99),
    free_threshold: nil, # Never free
    delivery_days: 1,
    cutoff_time: "12:00"
  )

  attr_reader :tiers

  # @param tiers [Array<ShippingTier>] Available shipping tiers
  def initialize(tiers: [STANDARD_TIER, EXPRESS_TIER, OVERNIGHT_TIER])
    @tiers = tiers
    validate_tiers!
  end

  # Calculate shipping cost for a specific tier
  # @param amount [Money] The order subtotal
  # @param tier_name [String] The tier name (e.g., "Standard Shipping")
  # @return [Money] The shipping cost
  def calculate(amount, tier_name:)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    tier = find_tier(tier_name)
    raise ArgumentError, "Tier '#{tier_name}' not found" unless tier

    tier.calculate_cost(amount)
  end

  # Get all available tiers with their costs for an amount
  # @param amount [Money] The order subtotal
  # @return [Array<Hash>] Array of tier information
  def available_tiers(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    tiers.map do |tier|
      {
        name: tier.name,
        cost: tier.calculate_cost(amount),
        delivery_days: tier.delivery_days,
        cutoff_time: tier.cutoff_time,
        free_shipping: tier.qualifies_for_free_shipping?(amount)
      }
    end
  end

  # Get estimated delivery date for a tier
  # @param tier_name [String] The tier name
  # @param order_time [Time] The order time (defaults to now)
  # @return [Date] Estimated delivery date
  def estimated_delivery_date(tier_name:, order_time: Time.current)
    tier = find_tier(tier_name)
    raise ArgumentError, "Tier '#{tier_name}' not found" unless tier

    # Check if order is before cutoff time
    cutoff_hour, cutoff_minute = tier.cutoff_time.to_s.split(":").map(&:to_i)
    cutoff_time = order_time.change(hour: cutoff_hour, min: cutoff_minute)

    # If after cutoff, add an extra day
    extra_days = order_time > cutoff_time ? 1 : 0

    # Skip weekends (simplified - doesn't account for holidays)
    delivery_date = order_time.to_date + tier.delivery_days.days + extra_days.days

    # If delivery falls on weekend, move to Monday
    while delivery_date.saturday? || delivery_date.sunday?
      delivery_date += 1.day
    end

    delivery_date
  end

  # Get the cheapest tier for an amount
  # @param amount [Money] The order subtotal
  # @return [ShippingTier]
  def cheapest_tier(amount)
    tiers.min_by { |tier| tier.calculate_cost(amount).to_f }
  end

  # Get the fastest tier
  # @return [ShippingTier]
  def fastest_tier
    tiers.min_by(&:delivery_days)
  end

  private

  def find_tier(tier_name)
    tiers.find { |tier| tier.name == tier_name }
  end

  def validate_tiers!
    raise ArgumentError, "Must have at least one tier" if tiers.empty?

    tiers.each do |tier|
      unless tier.is_a?(ShippingTier)
        raise ArgumentError, "All tiers must be ShippingTier instances"
      end
    end
  end
end
