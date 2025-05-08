class Coffee < ApplicationRecord
  has_many :coffee_variants, dependent: :destroy

  validates :name, presence: true
  validates :roast_type, inclusion: { in: %w[light medium dark], allow_nil: true }

  scope :active, -> { where(active: true) }
  scope :by_roast_type, ->(type) { where(roast_type: type) }

  # Get price for a specific size variant
  def price(size)
    variant = coffee_variants.find_by(size: size)
    variant&.price || 0
  end

  # Get all available sizes
  def sizes
    coffee_variants.pluck(:size)
  end

  # Get the cheapest price (for display purposes)
  def starting_price
    coffee_variants.minimum(:price) || 0
  end
end
