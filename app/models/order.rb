class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :coffee_variants, through: :order_items

  validates :status, presence: true, inclusion: { in: %w[cart pending completed cancelled] }
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :shipping_name, :shipping_address, :shipping_city,
            :shipping_state, :shipping_zip, :shipping_country,
            presence: true, if: :requires_shipping?

  validates :payment_method, presence: true, if: :completed?
  validates :payment_transaction_id, presence: true, if: :completed?

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

  def recalculate_total!
    self.total = order_items.sum { |item| item.price * item.quantity }
    save
  end

  def self.current_cart_for(user)
    user.orders.cart.first_or_create!
  end

  def cart?
    status == 'cart'
  end

  def completed?
    status == 'completed'
  end

  def pending?
    status == 'pending'
  end

  def cancelled?
    status == 'cancelled'
  end

  def requires_shipping?
    !cart?
  end

  def has_items?
    order_items.any?
  end

  def subtotal
    total
  end

  def tax
    subtotal * 0.09
  end

  def shipping_cost
    subtotal >= 50 ? 0 : 5.99
  end

  def grand_total
    subtotal + tax + shipping_cost
  end

  def shipping_address_complete?
    shipping_name.present? &&
      shipping_address.present? &&
      shipping_city.present? &&
      shipping_state.present? &&
      shipping_zip.present? &&
      shipping_country.present?
  end
end
