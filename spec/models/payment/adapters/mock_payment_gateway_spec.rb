require 'rails_helper'

RSpec.describe Payment::Adapters::MockPaymentGateway do
  subject(:gateway) { described_class.new }

  describe '#charge' do
    let(:payment_details) { { card_number: card_number } }
    let(:metadata) { { order_id: 1 } }

    context 'with approved card' do
      let(:card_number) { described_class::APPROVED_CARD }

      it 'returns successful result' do
        result = gateway.charge(amount: 100.00, payment_details: payment_details, metadata: metadata)

        expect(result).to be_success
        expect(result.transaction_id).to start_with('mock_')
        expect(result.message).to eq('Payment approved')
      end
    end

    context 'with declined card' do
      let(:card_number) { described_class::DECLINED_CARD }

      it 'returns failed result' do
        result = gateway.charge(amount: 100.00, payment_details: payment_details, metadata: metadata)

        expect(result).to be_failure
        expect(result.message).to include('insufficient funds')
      end
    end

    context 'with error card' do
      let(:card_number) { described_class::ERROR_CARD }

      it 'returns failed result with gateway error' do
        result = gateway.charge(amount: 100.00, payment_details: payment_details, metadata: metadata)

        expect(result).to be_failure
        expect(result.message).to include('gateway error')
      end
    end

    context 'with invalid amount' do
      let(:card_number) { described_class::APPROVED_CARD }

      it 'raises ArgumentError for negative amount' do
        expect {
          gateway.charge(amount: -10.00, payment_details: payment_details)
        }.to raise_error(ArgumentError, 'Amount must be positive')
      end

      it 'raises ArgumentError for zero amount' do
        expect {
          gateway.charge(amount: 0, payment_details: payment_details)
        }.to raise_error(ArgumentError, 'Amount must be positive')
      end
    end
  end

  describe '#refund' do
    it 'returns successful result' do
      result = gateway.refund(transaction_id: 'txn_123', amount: 50.00)

      expect(result).to be_success
      expect(result.transaction_id).to start_with('mock_')
      expect(result.message).to eq('Refund processed')
      expect(result.metadata[:original_transaction_id]).to eq('txn_123')
    end

    context 'with invalid amount' do
      it 'raises ArgumentError' do
        expect {
          gateway.refund(transaction_id: 'txn_123', amount: -10.00)
        }.to raise_error(ArgumentError, 'Amount must be positive')
      end
    end
  end

  describe '#available?' do
    it 'returns true' do
      expect(gateway).to be_available
    end
  end
end
