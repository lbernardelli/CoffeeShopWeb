require 'rails_helper'

RSpec.describe CoffeeApp::Services::CheckoutService do
  subject(:service) { described_class.new(order, payment_gateway: payment_gateway) }

  let(:order) { create(:order, :cart, :with_items) }
  let(:payment_gateway) { instance_double(CoffeeApp::Payment::PaymentGateway) }

  let(:shipping_params) do
    {
      name: 'John Doe',
      address: '123 Main St',
      city: 'New York',
      state: 'NY',
      zip: '10001',
      country: 'US'
    }
  end

  let(:payment_params) do
    {
      card_number: '4111111111111111',
      expiry_month: '12',
      expiry_year: '2025',
      cvv: '123',
      cardholder_name: 'John Doe'
    }
  end

  before do
    order.recalculate_total!
    allow(payment_gateway).to receive(:available?).and_return(true)
    allow(payment_gateway).to receive(:charge)
    allow(payment_gateway).to receive(:refund)
  end

  describe '#initialize' do
    context 'with valid dependencies' do
      it 'accepts order and payment gateway' do
        expect(service.order).to eq(order)
        expect(service.payment_gateway).to eq(payment_gateway)
      end
    end

    context 'with invalid dependencies' do
      it 'raises error when order is nil' do
        expect {
          described_class.new(nil, payment_gateway: payment_gateway)
        }.to raise_error(ArgumentError, 'Order cannot be nil')
      end

      it 'raises error when payment gateway is nil' do
        expect {
          described_class.new(order, payment_gateway: nil)
        }.to raise_error(ArgumentError, 'Payment gateway cannot be nil')
      end

      it 'raises error when payment gateway does not implement interface' do
        invalid_gateway = double('InvalidGateway')

        expect {
          described_class.new(order, payment_gateway: invalid_gateway)
        }.to raise_error(ArgumentError, /must implement PaymentGateway interface/)
      end
    end
  end

  describe '#process' do
    context 'with successful payment' do
      let(:payment_result) do
        CoffeeApp::Payment::PaymentResult.new(
          success: true,
          transaction_id: 'txn_123',
          message: 'Payment approved'
        )
      end

      before do
        allow(payment_gateway).to receive(:charge).and_return(payment_result)
      end

      it 'updates order with shipping information' do
        service.process(shipping_params: shipping_params, payment_params: payment_params)

        order.reload
        expect(order.shipping_name).to eq('John Doe')
        expect(order.shipping_address).to eq('123 Main St')
        expect(order.shipping_city).to eq('New York')
        expect(order.shipping_state).to eq('NY')
        expect(order.shipping_zip).to eq('10001')
        expect(order.shipping_country).to eq('US')
      end

      it 'charges payment gateway with correct amount' do
        expect(payment_gateway).to receive(:charge).with(
          amount: order.grand_total,
          payment_details: hash_including(
            card_number: '4111111111111111',
            cardholder_name: 'John Doe'
          ),
          metadata: hash_including(
            order_id: order.id,
            user_id: order.user_id
          )
        )

        service.process(shipping_params: shipping_params, payment_params: payment_params)
      end

      it 'marks order as completed' do
        service.process(shipping_params: shipping_params, payment_params: payment_params)

        order.reload
        expect(order.status).to eq('completed')
        expect(order.payment_method).to eq('credit_card')
        expect(order.payment_transaction_id).to eq('txn_123')
      end

      it 'returns successful result' do
        result = service.process(shipping_params: shipping_params, payment_params: payment_params)

        expect(result).to be_success
        expect(result.order).to eq(order)
        expect(result.message).to eq('Order completed successfully')
      end
    end

    context 'with failed payment' do
      let(:payment_result) do
        CoffeeApp::Payment::PaymentResult.new(
          success: false,
          message: 'Card declined'
        )
      end

      before do
        allow(payment_gateway).to receive(:charge).and_return(payment_result)
      end

      it 'does not mark order as completed' do
        service.process(shipping_params: shipping_params, payment_params: payment_params)

        order.reload
        expect(order.status).to eq('cart')
        expect(order.payment_transaction_id).to be_nil
      end

      it 'preserves shipping information for retry' do
        service.process(shipping_params: shipping_params, payment_params: payment_params)

        order.reload
        expect(order.shipping_name).to eq('John Doe')
      end

      it 'returns failed result with payment message' do
        result = service.process(shipping_params: shipping_params, payment_params: payment_params)

        expect(result).to be_failure
        expect(result.message).to eq('Card declined')
      end
    end

    context 'with validation errors' do
      it 'raises error when order has no items' do
        empty_order = create(:order, :cart)

        service = described_class.new(empty_order, payment_gateway: payment_gateway)

        expect {
          service.process(shipping_params: shipping_params, payment_params: payment_params)
        }.to raise_error(CoffeeApp::Services::CheckoutError, 'Order must have items')
      end

      it 'raises error when payment gateway is unavailable' do
        allow(payment_gateway).to receive(:available?).and_return(false)

        expect {
          service.process(shipping_params: shipping_params, payment_params: payment_params)
        }.to raise_error(CoffeeApp::Services::CheckoutError, 'Payment gateway is not available')
      end

      it 'raises error when shipping information is incomplete' do
        incomplete_shipping = shipping_params.merge(address: '')

        expect {
          service.process(shipping_params: incomplete_shipping, payment_params: payment_params)
        }.to raise_error(CoffeeApp::Services::CheckoutError, 'Incomplete shipping information')
      end
    end
  end
end
