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

  scope :cart, -> { where(status: "cart") }
  scope :completed, -> { where(status: "completed") }

  def add_item(coffee_variant, quantity = 1)
    existing_item = order_items.find_by(coffee_variant: coffee_variant)

    if existing_item
      existing_item.update!(quantity: existing_item.quantity + quantity)
    else
      order_items.create!(
        coffee_variant: coffee_variant,
        quantity: quantity,
        price: coffee_variant.price
      )
    end

    recalculate_total!
    order_items.reload
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
    status == "cart"
  end

  def completed?
    status == "completed"
  end

  def pending?
    status == "pending"
  end

  def cancelled?
    status == "cancelled"
  end

  def requires_shipping?
    !cart?
  end

  def has_items?
    order_items.any?
  end

  def subtotal
    Orders::Money.new(total)
  end

  def tax
    tax_calculator.calculate(subtotal)
  end

  def shipping_cost
    shipping_calculator.calculate(subtotal)
  end

  def grand_total
    subtotal + tax + shipping_cost
  end

  def grand_total_amount
    grand_total.to_f
  end

  # Check if order qualifies for free shipping
  def free_shipping?
    shipping_calculator.qualifies_for_free_shipping?(subtotal)
  end

  # Amount remaining to qualify for free shipping
  def remaining_for_free_shipping
    shipping_calculator.remaining_for_free_shipping(subtotal)
  end

  private

  def tax_calculator
    @tax_calculator ||= Orders::TaxCalculator.new
  end

  def shipping_calculator
    @shipping_calculator ||= Orders::ShippingCalculator.new
  end

  public

  def shipping_address_complete?
    shipping_name.present? &&
      shipping_address.present? &&
      shipping_city.present? &&
      shipping_state.present? &&
      shipping_zip.present? &&
      shipping_country.present?
  end
end
