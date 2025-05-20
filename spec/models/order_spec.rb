require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      order = Order.reflect_on_association(:user)
      expect(order.macro).to eq(:belongs_to)
    end

    it 'has many order items' do
      order = Order.reflect_on_association(:order_items)
      expect(order.macro).to eq(:has_many)
      expect(order.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    it 'validates presence of status' do
      order = build(:order, status: nil)
      expect(order).not_to be_valid
      expect(order.errors[:status]).to include("can't be blank")
    end

    it 'validates status is in valid list' do
      order = build(:order, status: 'invalid')
      expect(order).not_to be_valid
      expect(order.errors[:status]).to include('is not included in the list')
    end
  end

  describe '#add_item' do
    let(:order) { create(:order) }
    let(:coffee_variant) { create(:coffee_variant, price: 15.99) }

    it 'adds new item to cart' do
      expect {
        order.add_item(coffee_variant, 2)
      }.to change(order.order_items, :count).by(1)
    end

    it 'increments quantity for existing item' do
      order.add_item(coffee_variant, 1)

      expect {
        order.add_item(coffee_variant, 2)
      }.not_to change(order.order_items, :count)

      expect(order.order_items.first.quantity).to eq(3)
    end

    it 'recalculates total' do
      order.add_item(coffee_variant, 2)
      expect(order.total).to eq(31.98)
    end
  end

  describe '#grand_total' do
    let(:order) { create(:order, :with_items) }

    it 'includes subtotal, tax, and shipping' do
      order.recalculate_total!
      expected = order.subtotal + order.tax + order.shipping_cost
      expect(order.grand_total).to eq(expected)
    end
  end
end
