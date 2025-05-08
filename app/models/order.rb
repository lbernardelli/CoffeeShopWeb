class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :coffee_variants, through: :order_items

  validates :status, presence: true, inclusion: { in: %w[cart pending completed cancelled] }
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :cart, -> { where(status: 'cart') }
  scope :completed, -> { where(status: 'completed') }

  def add_item(coffee_variant, quantity = 1)
    existing_item = order_items.find_by(coffee_variant: coffee_variant)

    if existing_item
      existing_item.update(quantity: existing_item.quantity + quantity)
    else
      order_items.create!(
        coffee_variant: coffee_variant,
        quantity: quantity,
        price: coffee_variant.price
      )
    end

    recalculate_total!
    self
  end

  # Calculate total from items (following code_test pattern)
  def recalculate_total!
    self.total = order_items.sum { |item| item.price * item.quantity }
    save
  end

  def self.current_cart_for(user)
    user.orders.cart.first_or_create!
  end
end
