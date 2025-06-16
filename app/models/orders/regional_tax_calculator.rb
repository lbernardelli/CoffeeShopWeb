# Service object for calculating taxes based on region (state/country)
class Orders::RegionalTaxCalculator < Orders::TaxCalculator
  # Tax rates by US state
  STATE_TAX_RATES = {
    "AL" => 0.04,   # Alabama
    "AK" => 0.00,   # Alaska (no state sales tax)
    "AZ" => 0.056,  # Arizona
    "CA" => 0.0725, # California
    "CO" => 0.029,  # Colorado
    "FL" => 0.06,   # Florida
    "GA" => 0.04,   # Georgia
    "IL" => 0.0625, # Illinois
    "IN" => 0.07,   # Indiana
    "MA" => 0.0625, # Massachusetts
    "MI" => 0.06,   # Michigan
    "MN" => 0.06875,# Minnesota
    "NY" => 0.04,   # New York
    "NC" => 0.0475, # North Carolina
    "OH" => 0.0575, # Ohio
    "PA" => 0.06,   # Pennsylvania
    "TX" => 0.0625, # Texas
    "VA" => 0.053,  # Virginia
    "WA" => 0.065,  # Washington
    # Add more states as needed
  }.freeze

  # Tax rates by country
  COUNTRY_TAX_RATES = {
    "US" => 0.09,   # Default US rate
    "CA" => 0.05,   # Canada GST (simplified)
    "GB" => 0.20,   # UK VAT
    "DE" => 0.19,   # Germany VAT
    "FR" => 0.20,   # France VAT
    "AU" => 0.10,   # Australia GST
    "JP" => 0.10,   # Japan consumption tax
    "BR" => 0.17,   # Brazil (simplified)
  }.freeze

  attr_reader :region, :region_type

  # @param region [String] State code (US) or country code
  # @param region_type [Symbol] :state or :country
  # @param fallback_rate [Float] Fallback rate if region not found
  def initialize(region:, region_type: :state, fallback_rate: DEFAULT_RATE)
    @region = region.to_s.upcase
    @region_type = region_type.to_sym
    @fallback_rate = fallback_rate

    rate = determine_rate
    super(rate: rate)
  end

  # Calculate tax with regional rules
  # @param amount [Money] The amount to calculate tax on
  # @return [Money] The tax amount
  def calculate(amount)
    raise ArgumentError, "Amount must be a Money object" unless amount.is_a?(Orders::Money)

    # Some regions have tax-exempt thresholds or special rules
    return Orders::Money.new(0, currency: amount.currency) if tax_exempt?(amount)

    super(amount)
  end

  # Get the tax rate name/description
  # @return [String]
  def tax_name
    case region_type
    when :state
      "#{region} State Sales Tax"
    when :country
      country_tax_name
    else
      "Sales Tax"
    end
  end

  # Check if specific items or amounts are tax-exempt in this region
  # @param amount [Money] The amount to check
  # @return [Boolean]
  def tax_exempt?(amount)
    # Example: Alaska has no state sales tax
    return true if region_type == :state && region == "AK"

    # Add more exemption rules as needed
    false
  end

  private

  def determine_rate
    case region_type
    when :state
      STATE_TAX_RATES.fetch(region, @fallback_rate)
    when :country
      COUNTRY_TAX_RATES.fetch(region, @fallback_rate)
    else
      @fallback_rate
    end
  end

  def country_tax_name
    case region
    when "GB", "DE", "FR" then "VAT"
    when "CA", "AU" then "GST"
    when "JP" then "Consumption Tax"
    else "Sales Tax"
    end
  end
end
