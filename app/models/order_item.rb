class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :coffee_variant
  has_one :coffee, through: :coffee_variant

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  # Subtotal for this item (following code_test OrderItem.price pattern)
  def subtotal
    price * quantity
  end

  # Get the coffee name for display
  def coffee_name
    coffee_variant.coffee.name
  end

  # Get the size for display
  def size
    coffee_variant.size
  end
end
